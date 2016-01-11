require 'tempfile'
require 'open-uri'
require 'fileutils'
require 'net/http'

class CreateDatafileFromRemoteJob < ProgressJob::Base
  
  def initialize(dataset_id, datafile, remote_url, filename, filesize)
    @remote_url = remote_url
    @dataset_id = dataset_id
    @datafile = datafile
    @filename = filename

    if filesize.to_f < 10000
      progress_max = 2
    else
      progress_max = (filesize.to_f/10000).to_i + 1
    end

    super progress_max: progress_max
  end

  def perform

    dir_name = "#{Rails.root}/public/uploads/#{@dataset_id}"

    FileUtils.mkdir_p(dir_name) unless File.directory?(dir_name)

    filepath = "#{dir_name}/#{@filename}"

    File.open(filepath, 'wb+') do |outfile|
      uri = URI.parse(@remote_url)
      Net::HTTP.start(uri.host,uri.port, :use_ssl => (uri.scheme == 'https')  ){ |http|
        http.request_get(uri.path){ |res|

          res.read_body{ |seg|
            outfile << seg
            update_progress()
          }
        }
      }

    end


    if File.file?(filepath)
      @datafile.binary = Rails.root.join("public/uploads/#{@dataset_id}/#{@filename}").open
      @datafile.save!
    end

  end

end

