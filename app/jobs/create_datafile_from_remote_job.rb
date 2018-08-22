require 'tempfile'
require 'open-uri'
require 'fileutils'
require 'net/http'
require 'aws-sdk-s3'


class CreateDatafileFromRemoteJob < ProgressJob::Base

  FIVE_MB = 1024 * 1024 * 5

  def initialize(dataset_id, datafile, remote_url, filename, filesize)
    @remote_url = remote_url
    @dataset_id = dataset_id
    @datafile = datafile
    @filename = filename
    @filesize = filesize #string because it is used in display

    if filesize.to_f < 4000
      progress_max = 2
    else
      progress_max = (filesize.to_f / 4000).to_i + 1
    end

    super progress_max: progress_max
  end

  def perform

    @datafile.storage_key = File.join(@datafile.web_id, @filename)

    if IDB_CONFIG[:aws][:s3_mode]


      upload_key = @datafile.storage_key
      upload_bucket = Application.storage_manager.draft_root.bucket


      if Application.storage_manager.draft_root.prefix
        upload_key = "#{Application.storage_manager.draft_root.prefix}#{@datafile.storage_key}"
      end

      client = Application.aws_client

      if @filesize.to_f < FIVE_MB
        web_contents = open(@remote_url) {|f| f.read}
        Application.storage_manager.draft_root.copy_io_to(@datafile.storage_key, web_contents, nil, @filesize.to_f)

      else

        parts = "["

        file_parts = {}

        seg_queue = Queue.new

        mutex = Mutex.new

        segs_complete = false
        segs_todo = 0
        segs_done = 0



        begin

          upload_id = aws_mulitpart_start(client, upload_bucket, upload_key)

          seg_producer = Thread.new do

            uri = URI.parse(@remote_url)

            Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https')) {|http|
              http.request_get(uri.path) {|res|

                res.read_body {|seg|
                  mutex.synchronize {
                    segs_todo = segs_todo + 1
                    # Rails.logger.warn("seg class: #{seg.class}")
                    # Rails.logger.warn("seg #{parts_todo} produced")
                  }
                  seg_queue << seg
                }
              }
            }
            mutex.synchronize {
              segs_complete = true
              Rails.logger.warn("done with request")
            }

          end

          seg_consumer = Thread.new do

            part_number = 1

            part_IO = StringIO.new('', 'wb+')

            while seg = seg_queue.deq # wait for nil to break loop

              part_IO << seg

              if part_IO.size > FIVE_MB
                mutex.synchronize {
                  Rails.logger.warn("part_IO.size: #{part_IO.size}")
                }
                tmp_file = Tempfile.new("part_#{part_number}")
                tmp_file.binmode
                tmp_file.write part_IO.read
                if part_IO && !part_IO.closed?
                  part_IO.close
                end

                part_IO = StringIO.new('', 'wb+')

                mutex.synchronize {
                  etag = aws_upload_part(client, tmp_file, upload_bucket, upload_key, part_number, upload_id)
                  parts = %Q[#{parts}{etag: "\\"#{etag}\\"", part_number: #{part_number},},]

                  Rails.logger.warn("Another part bites the dust: #{part_number}")
                  part_number = part_number + 1
                }

              end



              mutex.synchronize {
                segs_done = segs_done + 1
                # Rails.logger.warn("seg #{parts_done} consumed")
                # Rails.logger.warn("seg class: #{seg.class}")
              }

            end

            # upload last part, less than 5 MB
            tmp_file = Tempfile.new("part_#{part_number}")
            tmp_file.binmode
            tmp_file.write part_IO.read
            if part_IO && !part_IO.closed?
              part_IO.close
            end
            mutex.synchronize {
              etag = aws_upload_part(client, tmp_file, upload_bucket, upload_key, part_number, upload_id)
              parts = %Q[#{parts}{etag: "\\"#{etag}\\"", part_number: #{part_number},},]
              Rails.logger.warn("Another part bites the dust: #{part_number}")
              part_number = part_number + 1
            }

            mutex.synchronize do
              Rails.logger.warn("done with parts")
              parts = %Q(#{parts}])
              Rails.logger.warn(parts)
              final_response = aws_complete_upload(client, upload_bucket, upload_key, parts, upload_id)
            end

          end

          controller = Thread.new do

            stop = false

            while !stop
              sleep 1
              mutex.synchronize {
                if segs_complete && ( segs_done == segs_todo)
                  stop = true
                  Rails.logger.warn("Time to end this.")
                end
              }
            end

            seg_queue.close

          end




        rescue Exception => ex
          # ..|..
          #

          Rails.logger.warn("something went wrong during multipart upload")
          Rails.logger.warn(ex.class)
          Rails.logger.warn(ex.message)
          ex.backtrace.each do |line|
            Rails.logger.warn(line)
          end

          Application.aws_client.abort_multipart_upload({
                                                            bucket: upload_bucket,
                                                            key: upload_key,
                                                            upload_id: upload_id,
                                                        })


          raise ex

        end

      end

    else

      filepath = "#{Application.storage_manager.draft_root.path}/#{@datafile.storage_key}"

      dir_name = File.dirname(filepath)

      FileUtils.mkdir_p(dir_name) unless File.directory?(dir_name)

      File.open(filepath, 'wb+') do |outfile|
        uri = URI.parse(@remote_url)
        Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https')) {|http|
          http.request_get(uri.path) {|res|

            res.read_body {|seg|
              outfile << seg
              update_progress()
            }
          }
        }

      end


    end

    # confirm upload, and update datafile fields

    if Application.storage_manager.draft_root.exist?(@datafile.storage_key)

      @datafile.binary_name = @filename
      @datafile.storage_root = Application.storage_manager.draft_root.name
      @datafile.storage_key = File.join(@datafile.web_id, @filename)
      @datafile.binary_size = @filesize
      @datafile.save!
    end

  end

  def aws_mulitpart_start(client, upload_bucket, upload_key)
    start_response = client.create_multipart_upload({
                                                        bucket: upload_bucket,
                                                        key: upload_key,
                                                    })

    start_response.upload_id

  end

  def aws_upload_part(client, file_part, upload_bucket, upload_key, part_number, upload_id)

    part_response = client.upload_part({
                                           body: file_part,
                                           bucket: upload_bucket,
                                           key: upload_key,
                                           part_number: part_number,
                                           upload_id: upload_id,
                                       })

    part_response.etag

  end

  def aws_complete_upload(client, upload_bucket, upload_key, parts, upload_id)
    Rails.logger.warn ("completing upload")
    Rails.logger.warn(parts)

    # complete upload
    response = client.complete_multipart_upload({
                                                    bucket: upload_bucket,
                                                    key: upload_key,
                                                    multipart_upload: {parts: parts, },
                                                    upload_id: upload_id,
                                                })

    Rails.logger.warn(response.to_h)
  end

end

