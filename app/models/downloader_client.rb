require 'fileutils'
require 'json'
require 'uri'
require 'net/http'
require 'net/http/digest_auth'

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

    if target_arr.count == 0
      return nil
    end

    download_request_hash = Hash.new

    download_request_hash["root"]="idb"
    download_request_hash["zip_name"]="#{zipname}"
    download_request_hash["targets"]="#{targets_arr}"

    download_request_json = download_request_hash.to_json

    digest_auth = Net::HTTP::DigestAuth.new

    uri = URI.parse("#{IDB_CONFIG['downloader']['host']}:#{IDB_CONFIG['downloader']['port']}/downloads/create")
    uri.user = IDB_CONFIG['downloader']['user']
    uri.password =  IDB_CONFIG['downloader']['password']

    h = Net::HTTP.new uri.host, uri.port

    req = Net::HTTP::Post.new uri.request_uri

    begin

      res = h.request req
      # res is a 401 response with a WWW-Authenticate header

      auth = digest_auth.auth_header uri, res['www-authenticate'], 'POST'

      # create a new request with the Authorization header
      req = Net::HTTP::Post.new uri.request_uri
      req.add_field 'Authorization', auth

      req.content_type = "application/json"
      req.body = download_request_json

      Rails.logger.warn "Medusa Downloader Request START"
      Rails.logger.warn req
      Rails.logger.warn "Medusa Downloader Request END"

      # re-issue request with Authorization
      res = h.request req

      case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          Rails.logger.warn "Medusa Downloader Response START"
          Rails.logger.warn res.to_yaml
          Rails.logger.warn "Medusa Downloader Response START"
          return "www.google.com"

        else
          Rails.logger.warn res.to_yaml
          return nil
      end
    rescue Net::HTTPBadResponse, Net::HTTPServerError => error
      Rails.logger.warn error.message
      Rails.logger.warn res.to_yaml
      return nil
    end



  end

end