require 'net/http'
require 'net/https'
require 'uri'

class MedusaInfo

  def self.content_type_manifest
    user = IDB_CONFIG['medusa_info']['user']
    password = IDB_CONFIG['medusa_info']['password']

    uri = URI("#{IDB_CONFIG['medusa']['file_group_url']}/content_type_manifest.json?start")

    begin

      Net::HTTP.start(uri.host, uri.port,
                      :use_ssl => uri.scheme == 'https',
                      :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

        request = Net::HTTP::Get.new uri.request_uri
        request.basic_auth user, password

        response = http.request request # Net::HTTPResponse object

        response_hash = JSON.parse(response.body)

        return response_hash
      end

    rescue StandardError => error
      Rails.logger.warn "error getting content type manifest from medusa: #{error.message}"
      raise error
    end
  end

  def self.doi_filename_mimetype

    content_type_manifest = MedusaInfo.content_type_manifest

    raise("Unexpected result in content_type_manifest") unless content_type_manifest && content_type_manifest['records']

    type_records = content_type_manifest['records']

    return_hash = {}

    type_records.each do |type_record|

      path_arr = type_record['cfs_file_relative_path'].split('/')
      datafile_category = path_arr[3]

      if datafile_category == 'dataset_files'
        doi_uri = path_arr[2]

        doi_string = "10.#{doi_uri[7..10]}/#{doi_uri[12..31]}"

        if doi_uri[12] != 'f'
          doi_string = "10.#{doi_uri[7..11]}/#{doi_uri[13..32]}"
        end
        
        bytestream_name = path_arr[4]
        hash_key = "#{doi_string}_#{bytestream_name}".downcase

        mimetype = (type_record['content_type_name'])

        return_hash[hash_key] = mimetype

      end

    end

    return return_hash

  end

end