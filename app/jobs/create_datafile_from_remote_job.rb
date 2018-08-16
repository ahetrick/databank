require 'tempfile'
require 'open-uri'
require 'fileutils'
require 'net/http'
require 'aws-sdk-s3'

class CreateDatafileFromRemoteJob < ProgressJob::Base

  def initialize(dataset_id, datafile, remote_url, filename, filesize)
    @remote_url = remote_url
    @dataset_id = dataset_id
    @datafile = datafile
    @filename = filename
    @filesize = filesize

    if filesize.to_f < 10000
      progress_max = 2
    else
      progress_max = (filesize.to_f / 10000).to_i + 1
    end

    super progress_max: progress_max
  end

  def perform

    @datafile.storage_key = join(@datafile.web_id, @filename)

    if IDB_CONFIG[:aws][:s3_mode] == true

      # This sets up the aws s3 pre-signed url
      queue = Queue.new
      s3 = Aws::S3::Resource.new(region: IDB_CONFIG[:aws][:region])
      obj = s3.bucket(IDB_CONFIG[:storage][0][:bucket]).object(@datafile.storage_key)
      up_url = URI.parse(obj.presigned_url(:put))

      # This is the remote url that was passed in, the source of the file to upload
      down_uri = URI.parse(@remote_url)

      producer = Thread.new do
        # This is how I stream the file from the url, this code is based on something currently working
        Net::HTTP.start(down_uri.host, down_uri.port, :use_ssl => (down_uri.scheme == 'https')) {|http|
          http.request_get(down_uri.path) {|res|

            res.read_body {|seg|
              queue << seg
              update_progress()
            }
          }
        }
      end

      consumer = Thread.new do
        # turn queue input into body_stream ?
      end

      # This block is based on documenation for using pre-signed URLs to upload to aws
      Net::HTTP.start(up_url.host) do |http|
        http.send_request("PUT", up_url.request_uri, body_stream, {
            # This is required, or Net::HTTP will add a default unsigned content-type.
            "content-type" => "",
        })
      end


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
      @datafile.storage_key = join(@datafile.web_id, @filename)
      @datafile.binary_size = @filesize
      @datafile.save!
    end

  end

end

