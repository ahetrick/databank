class UserAbility < ActiveRecord::Base

  class << self

    def user_can?(model, model_id, ability, user)
      user ||= User::Shibboleth.new # guest user (not logged in)
      UserAbility.where(resource_type: model,
                        resource_id: model_id,
                        user_provider: user.provider,
                        user_uid: user.uid,
                        ability: ability).exists?

    end

    def update_internal_reviewers(dataset_key, form_netids = [])
      dataset = Dataset.find_by(key: dataset_key)
      raise("dataset not found") unless dataset
      current_netids = dataset.internal_reviewer_netids || []
      netids_to_remove = current_netids - form_netids
      netids_to_add = form_netids - current_netids
      netids_to_remove.each do |netid|
        remove_internal_reviewer(dataset_key, netid)
      end
      netids_to_add.each do |netid|
        add_internal_reviewer(dataset_key, netid)
      end
    end

    def update_internal_editors(dataset_key, form_netids = [])
      dataset = Dataset.find_by(key: dataset_key)
      raise("dataset not found") unless dataset
      current_netids = dataset.internal_editor_netids || []
      netids_to_remove = current_netids - form_netids
      netids_to_add = form_netids - current_netids
      netids_to_remove.each do |netid|
        remove_internal_editor(dataset_key, netid)
      end
      netids_to_add.each do |netid|
        add_internal_editor(dataset_key, netid)
      end
    end

    def add_internal_reviewer(dataset_key, netid)
      dataset = Dataset.find_by key: dataset_key
      raise("dataset not found") unless dataset
      grant_internal(dataset, netid, :view)
      grant_internal(dataset, netid, :view_files)
    end

    def remove_internal_reviewer(dataset_key, netid)
      dataset = Dataset.find_by key: dataset_key
      raise("dataset not found") unless dataset
      revoke_internal(dataset, netid, :view)
      revoke_internal(dataset, netid, :view_files)
    end

    def add_internal_editor(dataset_key, netid)
      dataset = Dataset.find_by key: dataset_key
      raise "dataset not found" unless dataset
      abilities = %i[
        edit
        update
        destroy
        request_review
        get_new_token
        get_current_token
        validiate_change2published
        publish
        destroy_file
      ]
      abilities.each do |ability|
        grant_internal(dataset, netid, ability)
      end
    end

    def self.remove_internal_editor(dataset_key, netid)
      dataset = Dataset.find_by key: dataset_key
      raise "dataset not found" unless dataset
      abilities = %i[
        edit
        update
        destroy
        request_review
        get_new_token
        get_current_token
        validiate_change2published
        publish
        destroy_file
      ]
      abilities.each do |ability|
        revoke_internal(dataset, netid, ability)
      end
    end

    def grant_internal(dataset, netid, ability)
      existing_record = UserAbility.find_by(resource_type: "Dataset",
                                                          resource_id: dataset.id,
                                                          user_provider: "shibboleth",
                                                          user_uid: "#{netid}@illinois.edu",
                                                          ability: ability)
      existing_record = UserAbility.create!(resource_type: "Dataset",
                                                          resource_id: dataset.id,
                                                          user_provider: "shibboleth",
                                                          user_uid: "#{netid}@illinois.edu",
                                                          ability: ability) unless existing_record
      raise "#{ability} record not created for #{netid}, #{dataset.key}" unless existing_record
    end

    def revoke_internal(dataset, netid, ability)
      existing_record = UserAbility.find_by(resource_type: "Dataset",
                                            resource_id: dataset.id,
                                            user_provider: "shibboleth",
                                            user_uid: "#{netid}@illinois.edu",
                                            ability: ability)
      existing_record.destroy if existing_record
    end
  end
end
