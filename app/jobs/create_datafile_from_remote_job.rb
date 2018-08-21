require 'tempfile'
require 'open-uri'
require 'fileutils'
require 'net/http'
require 'aws-sdk-s3'
require 'stringio'

class CreateDatafileFromRemoteJob < ProgressJob::Base

  FIVE_MB = 1024 * 1024 * 5

  def initialize(dataset_id, datafile, remote_url, filename, filesize)
    @remote_url = remote_url
    @dataset_id = dataset_id
    @datafile = datafile
    @filename = filename
    @filesize = filesize

    if filesize.to_f < 4000
      progress_max = 2
    else
      progress_max = (filesize.to_f / 4000).to_i + 1
    end

    super progress_max: progress_max
  end

  def perform

    encountered_error = false

    @datafile.storage_key = File.join(@datafile.web_id, @filename)

    if IDB_CONFIG[:aws][:s3_mode]

      queue = SizedQueue.new(FIVE_MB * 2)

      mutex = Mutex.new

      num_segs_in = 0
      num_segs_out = 0
      segs_in_done = false

      upload_key = @datafile.storage_key
      upload_bucket = Application.storage_manager.draft_root.bucket


      if Application.storage_manager.draft_root.prefix
        upload_key = "#{Application.storage_manager.draft_root.prefix}#{@datafile.storage_key}"
      end

      client = Application.aws_client

      # This is the remote url that was passed in, the source of the file to upload
      down_uri = URI.parse(@remote_url)

      producer = Thread.new do

        begin

          # This is how I stream the file from the url, this code is based on something currently working
          Net::HTTP.start(down_uri.host, down_uri.port, :use_ssl => (down_uri.scheme == 'https')) {|http|
            http.request_get(down_uri.path) {|res|

              res.read_body {|seg|
                queue << seg
                mutex.synchronize do
                  num_segs_in = num_segs_in + 1
                end
              }
            }
          }

          mutex.synchronize do
            segs_in_done = true
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

          queue.close if queue && !queue.closed?

          raise ex

        end

      end

      consumer = Thread.new do

        begin

          done = false

          Rails.logger.warn("creating mulitpart upload")
          Rails.logger.warn("upload_key: #{upload_key}")
          Rails.logger.warn("upload bucket: #{upload_bucket}")

          response = client.create_multipart_upload({
                                                        bucket: upload_bucket,
                                                        key: upload_key,
                                                    })

          upload_id = response.upload_id

          Rails.logger.warn("upload_id: #{upload_id}")

          parts = []

          buffer = StringIO.new

          part_number = 1



          loop do
            mutex.synchronize do
              if (segs_in_done && (num_segs_in == num_segs_out))
                done = true
              end
            end

            break if done
            
            seg = queue.deq

            mutex.synchronize do
              num_segs_out = num_segs_out + 1
            end

            buffer.write(seg)
            #Rails.logger.warn("buffer size: #{buffer.size.to_s}")
            if buffer.size > FIVE_MB

              buffer.close_write unless buffer.closed_write?

              if buffer.closed_read?
                Rail.logger.warn("There is your trouble.")
              end

              part_response = client.upload_part({
                                                     body: buffer.read,
                                                     bucket: upload_bucket,
                                                     key: upload_key,
                                                     part_number: part_number,
                                                     upload_id: upload_id,
                                                 })


              Rails.logger.warn("part_response.etag: #{part_response.etag}")

              part_hash = {etag: "\"#{part_response.etag}\"", part_number: part_number,}
              parts.push(part_hash)
              buffer = StringIO.new
              part_number = part_number + 1
              Rails.logger.warn("Another part bites the dust: #{part_number}")

            end
          end

          unless buffer.size <= 0

            # send the last part, which can be any size
            part_response = client.upload_part({
                                                   body: buffer.read,
                                                   bucket: upload_bucket,
                                                   key: upload_key,
                                                   part_number: part_number,
                                                   upload_id: upload_id,
                                               })

            part_hash = {etag: "\"#{part_response.etag}\"", part_number: part_number,}
            parts.push(part_hash)
            Rails.logger.warn("last part_response.etag: #{part_response.etag}")

          end

          buffer.close
          queue.close if queue && !queue.closed?

          Rails.logger.warn ("completing upload")
          Rails.logger.warn(parts)

          # complete upload
          response = client.complete_multipart_upload({
                                                          bucket: upload_bucket,
                                                          key: upload_key,
                                                          multipart_upload: {parts: parts,},
                                                          upload_id: upload_id,
                                                      })

          Rails.logger.warn(response.to_h)

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

          queue.close if queue && !queue.closed?

          raise ex

        end


      end

      producer.join
      consumer.join

    else

      filepath = Pathname.new(File.join(Application.storage_manager.draft_root.path, @datafile.storage_key))
      dirname = File.dirname(filepath)

      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

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

    if Application.storage_manager.draft_root.exist?(@datafile.storage_key)

      @datafile.binary_name = @filename
      @datafile.storage_root = Application.storage_manager.draft_root.name
      @datafile.storage_key = File.join(@datafile.web_id, @filename)
      @datafile.binary_size = @filesize
      @datafile.save!
    end

  end

end

