class UserAbility < ActiveRecord::Base

  def self.user_can?(model, model_id, ability, user)
    user ||= User::Shibboleth.new # guest user (not logged in)
    UserAbility.find_by(resource_type: model,
                        resource_id: model_id,
                        provider: user.provider,
                        user_uid: user.uid,
                        ability: ability).exists?

  end

  def self.add_internal_dataset_reviewer(dataset_key, netid)

    dataset = Dataset.find_by key: dataset_key

    raise "dataset not found" unless dataset

    existing_view_metadata_record = UserAbility.find_by(resource_type: "Dataset",
                                                        resource_id: dataset.id,
                                                        provider: "shibboleth",
                                                        user_uid: "#{netid}@illinois.edu",
                                                        ability: :view)

    UserAbility.create(dataset_id: dataset.id,
                       provider: "shibboleth",
                       user_uid: "#{netid}@illinois.edu",
                       ability: :view) unless existing_view_metadata_record

    existing_view_files_record = UserAbility.find_by(resource_type: "Dataset",
                                                     resource_id: dataset.id,
                                                     provider: "shibboleth",
                                                     user_uid: "#{netid}@illinois.edu",
                                                     ability: :view_files)
    UserAbility.create(dataset_id: dataset.id,
                       provider: "shibboleth",
                       user_uid: "#{netid}@illinois.edu",
                       ability: :view_files) unless existing_view_files_record

  end

  def self.remove_internal_dataset_reviewer(dataset_key, netid)

    dataset = Dataset.find_by key: dataset_key

    raise "dataset not found" unless dataset

    existing_view_metadata_record = UserAbility.find_by(resource_type: "Dataset",
                                                        resource_id: dataset.id,
                                                        provider: "shibboleth",
                                                        user_uid: "#{netid}@illinois.edu",
                                                        ability: :view)

    existing_view_metadata_record.destroy if existing_view_metadata_record

    existing_view_files_record = UserAbility.find_by(resource_type: "Dataset",
                                                     resource_id: dataset.id,
                                                        provider: "shibboleth",
                                                        user_uid: "#{netid}@illinois.edu",
                                                        ability: :view_files)

    existing_view_files_record.destroy if existing_view_files_record

  end
end
