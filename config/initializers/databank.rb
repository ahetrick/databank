require 'aws-sdk'
require 'tus/storage/s3'
require 'tus/storage/filesystem'

IDB_CONFIG = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]

Application.storage_manager = StorageManager.new

if IDB_CONFIG[:aws][:s3_mode] == true
  Aws.config.update({
                        region: IDB_CONFIG[:aws][:region],
                        credentials: Aws::Credentials.new(IDB_CONFIG[:aws][:access_key_id], IDB_CONFIG[:aws][:secret_access_key])
                    })

  Application.aws_signer = Aws::S3::Presigner.new

  Tus::Server.opts[:storage] = Tus::Storage::S3.new(
      bucket:            IDB_CONFIG[:storage][0][:bucket], # required
      access_key_id:     IDB_CONFIG[:aws][:access_key_id],
      secret_access_key: IDB_CONFIG[:aws][:secret_access_key],
      region:            IDB_CONFIG[:aws][:region],
      )

else
  Rails.logger.warn IDB_CONFIG[:aws][:s3_mode]
  Rails.logger.warn IDB_CONFIG[:storage][0][:path]
  Tus::Server.opts[:storage] = Tus::Storage::Filesystem.new("#{IDB_CONFIG[:storage][0][:path]}/cache" )
end

