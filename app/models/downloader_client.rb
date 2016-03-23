require 'json'
require 'curb'

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

    url = "#{IDB_CONFIG['downloader']['host']}:#{IDB_CONFIG['downloader']['port']}/downloads/create"
    Rails.logger.warn url

    begin

    client = Curl::Easy.new(url)
    client.http_auth_types = :digest
    client.username = user
    client.password = password
    client.post_body = download_request_json
    client.post
    client.headers = {'Content-Type' => 'application/json'}
    response = client.perform
    Rails.logger.warn client.body_str
    Rails.logger.warn "*** response:"
    Rails.logger.warn response
    rescue StandardError => error
      Rails.looger.warn error
      return nil

    end

    return nil


  end

end