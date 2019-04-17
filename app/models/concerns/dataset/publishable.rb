# frozen_string_literal: true

module Publishable
  extend ActiveSupport::Concern

  def publish(user)
    self.complete = Dataset.completion_check(self, user) == "ok"
    return {status: :error_occurred, error_text: Dataset.completion_check(self, user)} unless complete

    self.release_date ||= Date.current

    old_publication_state = publication_state

    if (old_publication_state != Databank::PublicationState::DRAFT) &&
        (!identifier || identifier == "")
      return {status:     :error_occurred,
              error_text: "Missing identifier for dataset that is not a draft. Dataset: #{key}"}
    end

    # set publication_state
    embargo_list = [Databank::PublicationState::Embargo::FILE, Databank::PublicationState::Embargo::METADATA]
    self.publication_state = if embargo && embargo_list.include?(embargo)
                               embargo
                             else
                               Databank::PublicationState::RELEASED
                             end

    if old_publication_state == Databank::PublicationState::DRAFT &&
        publication_state != Databank::PublicationState::DRAFT
      # remove deck directory, if it exists
      FileUtils.rm_rf(deck_location) if File.exist?(deck_location)
      # set release date to current if not embargo
      self.release_date = Date.current if publication_state == Databank::PublicationState::RELEASED
    end

    if Dataset.post_doi_metadata(self, user) && Dataset.post_doi(self, user)
      MedusaIngest.send_dataset_to_medusa(self)

      if IDB_CONFIG[:local_mode] && IDB_CONFIG[:local_mode] == true
        Rails.logger.warn "Dataset #{key} succesfully deposited."
      else
        begin
          notification = DatabankMailer.confirm_deposit(key)
          notification.deliver_now
        rescue StandardError => e
          notification = DatabankMailer.confirmation_not_sent(key, e)
          notification.deliver_now
        end
      end
      {status: :ok, old_publication_state: old_publication_state}
    else
      {status:     :error_occurred,
       error_text: "Error in publishing dataset has been logged for review by the Research Data Service."}
    end
  end
end
