require 'aws-sdk'
require 'aws-sdk-s3'
require 'tus/storage/s3'
require 'tus/storage/filesystem'

VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

PRODUCTION_PREFIXES = ["10.13012", "10.25988"]

DEMO_PREFIXES = ["10.26123"]

TEST_PREFIXES = ["10.70114"]

# puts Rails.application.credentials[:recaptcha][:site_key]
# puts Rails.application.credentials[:recaptcha][:secret_key]
# puts Rails.application.credentials[:illinois_experts][:key]
# puts Rails.application.credentials[:illinois_experts][:endpoint]
# puts Rails.application.credentials[Rails.env.to_sym][:admin][:netids]
# puts Rails.application.credentials[Rails.env.to_sym][:admin][:identities]
# puts Rails.application.credentials[Rails.env.to_sym][:admin][:tech_mail_list]
# puts Rails.application.credentials[Rails.env.to_sym][:admin][:materials_report_list]
# puts Rails.application.credentials[Rails.env.to_sym][:datacite][:endpoint]
# puts Rails.application.credentials[Rails.env.to_sym][:datacite][:username]
# puts Rails.application.credentials[Rails.env.to_sym][:datacite][:password]
# puts Rails.application.credentials[Rails.env.to_sym][:datacite][:shoulder]
# puts Rails.application.credentials[Rails.env.to_sym][:datacite][:url_base]
# puts Rails.application.credentials[Rails.env.to_sym][:test_datacite][:endpoint]
# puts Rails.application.credentials[Rails.env.to_sym][:test_datacite][:username]
# puts Rails.application.credentials[Rails.env.to_sym][:test_datacite][:password]
# puts Rails.application.credentials[Rails.env.to_sym][:test_datacite][:shoulder]
# puts Rails.application.credentials[Rails.env.to_sym][:test_datacite][:url_base]
# puts Rails.application.credentials[Rails.env.to_sym][:tasks_url]
# puts Rails.application.credentials[Rails.env.to_sym][:key_prefix]
# puts Rails.application.credentials[Rails.env.to_sym][:root_url_text]
# puts Rails.application.credentials[Rails.env.to_sym][:tmpdir]
# puts Rails.application.credentials[Rails.env.to_sym][:system_user_name]
# puts Rails.application.credentials[Rails.env.to_sym][:system_user_email]
# puts Rails.application.credentials[Rails.env.to_sym][:iiif_root]
# puts Rails.application.credentials[Rails.env.to_sym][:reserve_doi_netid]
# puts Rails.application.credentials[Rails.env.to_sym][:reserve_doi_role]
# puts Rails.application.credentials[Rails.env.to_sym][:aws][:s3_mode]
# puts Rails.application.credentials[Rails.env.to_sym][:aws][:access_key_id]
# puts Rails.application.credentials[Rails.env.to_sym][:aws][:secret_access_key]
# puts Rails.application.credentials[Rails.env.to_sym][:aws][:region]
# puts Rails.application.credentials[Rails.env.to_sym][:storage][:tmp_path]
# puts Rails.application.credentials[Rails.env.to_sym][:storage][:draft_type]
# puts Rails.application.credentials[Rails.env.to_sym][:storage][:draft_path]
# puts Rails.application.credentials[Rails.env.to_sym][:storage][:medusa_type]
# puts Rails.application.credentials[Rails.env.to_sym][:storage][:medusa_path]
# puts Rails.application.credentials[Rails.env.to_sym][:iiif][:draft_base]
# puts Rails.application.credentials[Rails.env.to_sym][:iiif][:medusa_base]
# puts Rails.application.credentials[Rails.env.to_sym][:amqp][:ssl]
# puts Rails.application.credentials[Rails.env.to_sym][:amqp][:port]
# puts Rails.application.credentials[Rails.env.to_sym][:amqp][:host]
# puts Rails.application.credentials[Rails.env.to_sym][:amqp][:user]
# puts Rails.application.credentials[Rails.env.to_sym][:amqp][:password]
# puts Rails.application.credentials[Rails.env.to_sym][:amqp][:verify_peer]
# puts Rails.application.credentials[Rails.env.to_sym][:medusa][:outgoing_queue]
# puts Rails.application.credentials[Rails.env.to_sym][:medusa][:incoming_queue]
# puts Rails.application.credentials[Rails.env.to_sym][:medusa][:medusa_path_root]
# puts Rails.application.credentials[Rails.env.to_sym][:medusa][:file_group_url]
# puts Rails.application.credentials[Rails.env.to_sym][:medusa][:datasets_url_base]
# puts Rails.application.credentials[Rails.env.to_sym][:downloader][:ssl]
# puts Rails.application.credentials[Rails.env.to_sym][:downloader][:host]
# puts Rails.application.credentials[Rails.env.to_sym][:downloader][:realm]
# puts Rails.application.credentials[Rails.env.to_sym][:downloader][:user]
# puts Rails.application.credentials[Rails.env.to_sym][:downloader][:password]
# puts Rails.application.credentials[Rails.env.to_sym][:medusa_info][:ssl]
# puts Rails.application.credentials[Rails.env.to_sym][:medusa_info][:host]
# puts Rails.application.credentials[Rails.env.to_sym][:medusa_info][:user]
# puts Rails.application.credentials[Rails.env.to_sym][:medusa_info][:password]

IDB_CONFIG = YAML.load(ERB.new(File.read(File.join(Rails.root, 'config', 'databank.yml'))).result)
STORAGE_CONFIG = YAML.load(ERB.new(File.read(File.join(Rails.root, 'config', 'medusa_storage.yml'))).result)[Rails.env]
AMQP_CONFIG = YAML.load(ERB.new(File.read(File.join(Rails.root, 'config', 'amqp.yml'))).result)[Rails.env]

Application.storage_manager = StorageManager.new

Tus::Server.opts[:max_size] = 2 * 1024*1024*1024*1024 # 2TB

if IDB_CONFIG[:aws][:s3_mode] == true

  Aws.config.update({
                        region: IDB_CONFIG[:aws][:region],
                        credentials: Aws::Credentials.new(IDB_CONFIG[:aws][:access_key_id], IDB_CONFIG[:aws][:secret_access_key])
                    })

  Application.aws_signer = Aws::S3::Presigner.new

  Application.aws_client = Aws::S3::Client.new

  Tus::Server.opts[:storage] = Tus::Storage::S3.new(prefix: 'uploads',
      bucket:            STORAGE_CONFIG[:storage][0][:bucket], # required
      access_key_id:     IDB_CONFIG[:aws][:access_key_id],
      secret_access_key: IDB_CONFIG[:aws][:secret_access_key],
      region:            IDB_CONFIG[:aws][:region],
      )

else

  Tus::Server.opts[:storage] = Tus::Storage::Filesystem.new(STORAGE_CONFIG[:storage][0][:path] )

end

# create identity invitees for admins
IDB_CONFIG[:admin][:identities].split(", ").each do |email|

  # weird logic to accomdate intitilzation/migration order for deploy

  if ActiveRecord::Base.connection.table_exists? 'invitees'
    invitee = Invitee.find_by_email(email);
    if invitee && invitee.has_attribute?(:expires_at)
      invitee.update_attribute(:expires_at, Time.now + 1.years)
    elsif ActiveRecord::Base.connection.column_exists?(:invitees, :expires_at)
      Invitee.create!(email:email, expires_at: Time.now + 1.years, role: Databank::UserRole::ADMIN)
    end
  end

end


