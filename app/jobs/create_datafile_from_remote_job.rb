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
    @filesize = filesize

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
        web_contents  = open(@remote_url) {|f| f.read }
        Application.storage_manager.draft_root.copy_io_to(upload_key, web_contents, nil, @filesize)

      else

        parts = []
        part_number = 1
        file_parts = {}

        begin

          upload_id = aws_mulitpart_start(client, upload_bucket, upload_key)

          file_parts[part_number] = Tempfile.new("part#{part_number}")

          uri = URI.parse(@remote_url)
          Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https')) {|http|
            http.request_get(uri.path) {|res|

              res.read_body {|seg|
                file_parts[part_number] << seg

                if file_parts[part_number].size.to_f > FIVE_MB

                  file_parts[part_number].close
                  etag = aws_upload_part(client, file_parts[part_number], upload_bucket, upload_key, part_number, upload_id)
                  part_hash = {etag: "\"#{etag}\"", part_number: part_number,}
                  parts.push(part_hash)
                  Rails.logger.warn("Another part bites the dust: #{part_number}")
                  part_number = part_number + 1
                  file_parts[part_number] = Tempfile.new("part#{part_number}")

                end

                update_progress
              }

              # handle last part, which does not have to be 5 MB
              file_parts[part_number].close
              etag = aws_upload_part(client, file_parts[part_number], upload_bucket, upload_key, part_number, upload_id)
              part_hash = {etag: "\"#{etag}\"", part_number: part_number,}
              parts.push(part_hash)
              Rails.logger.warn("Another part bites the dust: #{part_number}")

              aws_complete_upload(client, upload_bucket, upload_key, parts, upload_id)

            }
          }

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
        Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https')) { |http|
          http.request_get(uri.path) { |res|

            res.read_body { |seg|
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
                                                    multipart_upload: {parts: parts,},
                                                    upload_id: upload_id,
                                                })

    Rails.logger.warn(response.to_h)
  end

end

