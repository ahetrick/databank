require 'aws-sdk'

IDB_CONFIG = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]

Application.storage_manager = StorageManager.new

Application.aws_signer = Aws::S3::Presigner.new

Aws.config.update({
                      region: IDB_CONFIG[:aws][:region],
                      credentials: Aws::Credentials.new(IDB_CONFIG[:aws][:access_key_id], IDB_CONFIG[:aws][:secret_access_key])
                  })
