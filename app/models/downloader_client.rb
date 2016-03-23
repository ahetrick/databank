require 'json'
require 'curb'


class DownloaderClient
  include ActiveModel::Conversion
  include ActiveModel::Naming

  #precondition: all targets are in Medusa
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
        if !df.medusa_path || df.medusa_path == ''
          Rails.logger.warn "no medusa path for #{df.to_yaml}"
          return nil
        end
        target_hash = Hash.new
        target_hash["type"]="file"
        target_hash["path"]="#{df.medusa_path}"
        targets_arr.push(target_hash)
      end
    end

    if targets_arr.count == 0
      return nil
    end

    download_request_hash = Hash.new

    download_request_hash["root"]="idb"
    download_request_hash["zip_name"]="#{zipname}"
    download_request_hash["targets"]=targets_arr

    download_request_json = download_request_hash.to_json

    user = IDB_CONFIG['downloader']['user']
    password = IDB_CONFIG['downloader']['password']

    url = "#{IDB_CONFIG['downloader']['host']}:#{IDB_CONFIG['downloader']['port']}/downloads/create"

    begin

      client = Curl::Easy.new(url)
      client.http_auth_types = :digest
      client.username = user
      client.password = password
      client.post_body = download_request_json
      client.post
      client.headers = {'Content-Type' => 'application/json'}
      response = client.perform
      response_json = client.body_str
      response_hash = JSON.parse(client.body_str)
      if response_hash.has_key?("download_url")
        Rails.logger.warn "inside downloader client: #{response_hash["download_url"]}"
        return response_hash["download_url"]
      else
        Rails.logger.warn download_request_json
        Rails.logger.warn "unexpected downloader response: #{client.body_str}"
        return nil
      end

    rescue StandardError => error
      Rails.looger.warn error
      return nil
    end

    #should not get here
    return nil


  end

end