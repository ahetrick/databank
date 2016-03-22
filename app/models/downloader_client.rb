require 'fileutils'
require 'json'
require 'uri'
require 'net/http'

class DownloaderClient
  include ActiveModel::Conversion
  include ActiveModel::Naming

  def self.get_download_link(web_ids, zipname)
    #web_ids is expected to be an array
    num_files = 0
    if web_ids.respond_to?(:count)
      num_files = web_ids.count
    else
      return nil
    end
    if num_files == 0
      return nil
    end

    targets_arr = Array.new
    web_ids.each do |web_id|
      df = Datafile.find_by_web_id(web_id)
      if df
        target_hash = Hash.new
        target_hash['type']='file'
        target_hash['path']=df.bytestream_path
        targets_arr.push(target_hash.to_json)
      end
    end

    if targets_arr.count == 0
      return nil
    end

    download_request_hash = Hash.new

    download_request_hash["root"]="idb"
    download_request_hash["zip_name"]="#{zipname}"
    download_request_hash["targets"]="#{targets_arr}"

    download_request_json = download_request_hash.to_json

    user = IDB_CONFIG['downloader']['user']
    password = IDB_CONFIG['downloader']['password']

    uri = URI.parse("#{IDB_CONFIG['downloader']['host']}:#{IDB_CONFIG['downloader']['port']}/downloads/create")

    request = Net::HTTP::Post.new(uri.request_uri)
    request.basic_auth(user, password)
    request.content_type = "application/json"
    request.body = download_request_json

    Rails.logger.warn "request START"
    Rails.logger.warn request.to_yaml
    Rails.logger.warn "request STOP"

    sock = Net::HTTP.new(uri.host, uri.port)

    if uri.scheme == 'https'
      sock.use_ssl = true
    end

    begin

      response = sock.start { |http| http.request(request) }
      case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          Rails.logger.warn "*** success response START ***"
          Rails.logger.warn response.to_yaml
          Rails.logger.warn "*** success response END ***"
          return nil

        else
          Rails.logger.warn "failure response START"
          Rails.logger.warn response.to_yaml
          Rails.logger.warn "failure response END"
          return nil
      end

    rescue Net::HTTPBadResponse, Net::HTTPServerError => error
      Rails.logger.warn error.message
      Rails.logger.warn response.body
      return nil
    end

    return nil


  end

end