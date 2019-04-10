require 'aws-sdk'
require 'aws-sdk-s3'
require 'tus/storage/s3'
require 'tus/storage/filesystem'

IDB_CONFIG = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]

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
      bucket:            IDB_CONFIG[:storage][0][:bucket], # required
      access_key_id:     IDB_CONFIG[:aws][:access_key_id],
      secret_access_key: IDB_CONFIG[:aws][:secret_access_key],
      region:            IDB_CONFIG[:aws][:region],
      )

else

  Tus::Server.opts[:storage] = Tus::Storage::Filesystem.new(IDB_CONFIG[:storage][0][:path] )

end

# create identity invitees for admins
IDB_CONFIG[:admin_identities_list].split(", ").each do |email|

  # weird logic to accomdate intitilzation/migration order for deploy

  if ActiveRecord::Base.connection.table_exists? 'invitees'
    invitee = Invitee.find_by_email(email);
    if invitee && invitee.has_attribute?(:expires_at)
      invitee.update_attribute(:expires_at, Time.now + 1.years)
    elsif ActiveRecord::Base.connection.column_exists?(:invitees, :expires_at)
      Invitee.create!(email:email, expires_at: Time.now + 1.years, group: Databank::IdentityGroup::ADMIN, role: Databank::UserRole::ADMIN)
    end
  end


end


