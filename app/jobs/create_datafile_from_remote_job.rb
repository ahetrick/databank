require 'tempfile'
require 'open-uri'
require 'fileutils'
require 'net/http'

class CreateDatafileFromRemoteJob < ProgressJob::Base
  # queue_as :default

  def initialize(dataset_id, remote_url, filename, filesize)
    @remote_url = remote_url
    @dataset_id = dataset_id
    @filename = filename
    @filesize = filesize
    super progress_max: Integer(filesize)
  end

  def perform

    # Rails.logger.warn "anything!"

    # @progress_max.times do |count|
    #   update_progress
    # end

    dir_name = "#{Rails.root}/public/uploads/#{@dataset_id}"

    FileUtils.mkdir_p(dir_name) unless File.directory?(dir_name)

    filepath = "#{dir_name}/#{@filename}"

    if @progress_max < 10000
      stepsize = @progress_max/2
    else
      stepsize = 10000
    end

    File.open(filepath, 'wb+') do |outfile|
      uri = URI.parse(@remote_url)
      Net::HTTP.start(uri.host,uri.port, :use_ssl => (uri.scheme == 'https')  ){ |http|
        http.request_get(uri.path){ |res|

          # # Works with the response object as well:
          # res.each_header do |header_name, header_value|
          #   Rails.logger.warn "#{header_name} : #{header_value}"
          # end

          # seg_count = 1

          res.read_body{ |seg|
            #Rails.logger.warn "seg_count: #{seg_count}"
            outfile << seg
            #seg_count = seg_count + 1
            update_progress(step: stepsize)
          }
        }
      }


    end


    if File.file?(filepath)
      df = Datafile.create(:dataset_id => @dataset_id)
      df.binary = Rails.root.join("public/uploads/#{@dataset_id}/#{@filename}").open
      df.save!
    end



    # uri = URI.parse(@remote_url)
    # Net::HTTP.start(uri.host,uri.port){ |http|
    #   http.request_get(uri.path){ |res|
    #     res.read_body{ |seg|
    #       outfile << seg
    #       #hack -- adjust to suit:
    #       #sleep 0.005
    #     }
    #   }
    # }


    # f = open("/public/uploads/test.txt", "wb+")
    #
    # begin
    #   http.request_get(@remote_url) do |resp|
    #     resp.read_body do |segment|
    #       f.write(segment)
    #     end
    #   end
    # ensure
    #   f.close()
    # end

    # @progress_max.times do |count|W
    #   update_progress
    # end



  end

end



# class CreateDatafileFromRemoteJob < ProgressJob::Base
#   # queue_as :default
#
#   def initialize(dataset_id, remote_url, progress_max)
#     @remote_url = remote_url
#     @dataset_id = dataset_id
#     super progress_max: Integer(progress_max)
#   end
#
#   def perform
#
#    100.times do |count|
#
#       update_progress
#     end
#
#    Datafile.create(:remote_binary_url => @remote_url, :dataset_id => @dataset_id)
#
#   end
#
# end
