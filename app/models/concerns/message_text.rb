module MessageText
  extend ActiveSupport::Concern

  class_methods do

    def deposit_confirmation_notice(old_state, dataset)

      new_state = dataset.publication_state

      case new_state
        when Databank::PublicationState::RELEASED
          return %Q[Dataset was successfully published and the DataCite DOI is #{dataset.identifier}.<br/>The persistent link to this dataset is now <a href = "https://doi.org/#{dataset.identifier}">https://doi.org/#{dataset.identifier}</a>.<br/>There may be a delay before the persistent link will be in effect.  If this link does not redirect to the dataset immediately, try again in an hour.]

        when Databank::PublicationState::Embargo::METADATA
          return %Q[DataCite DOI #{dataset.identifier} successfully reserved.<br/>The persistent link to this dataset will be <a href = "https://doi.org/#{dataset.identifier}">https://doi.org/#{dataset.identifier}</a> starting #{dataset.release_date}.]

        when Databank::PublicationState::Embargo::FILE
          return %Q[Dataset record was successfully published and the DataCite DOI is #{dataset.identifier}.<br/>Although the record for your dataset will be publicly visible, your data files will not be made available until #{dataset.release_date.iso8601}.<br/>The persistent link to this dataset is now <a href = "https://doi.org/#{dataset.identifier}">https://doi.org/#{dataset.identifier}</a>.<br/>There may be a delay before the persistent link will be in effect.  If this link does not redirect to the dataset immediately, try again in an hour.]
      end

    end


    def publish_modal_msg(dataset)

      # This method should only be called if there are DataCite relevant changes, including release date

      effective_embargo = nil
      effective_release_date = Date.current.iso8601

      if dataset.release_date && dataset.release_date >= Date.current()
        if dataset.embargo
          effective_embargo = dataset.embargo
          effective_release_date = dataset.release_date.iso8601
        else
          Rails.logger.warn "no embargo but release date in future"
          Rails.logger.warn dataset.to_yaml
        end

      end

      msg = "<div class='confirm-modal-text'>"

      case effective_embargo

        when Databank::PublicationState::Embargo::FILE
          if dataset.publication_state == Databank::PublicationState::DRAFT
            msg << "<h4>This action will make your record public and create a DOI.</h4><hr/>"
            msg << "<ul>"
            msg << "<li>Your Illinois Data Bank dataset record will be publicly visible through search engines.</li>"
            msg << "<li>Although the record for your dataset will be publicly visible, your data files will not be made available until #{effective_release_date}.</li>"

          else
            msg << "<h4>This action will make your updates to your dataset record public.</h4><hr/>"
            msg << "<ul>"
          end

        when Databank::PublicationState::Embargo::METADATA
          if dataset.publication_state == Databank::PublicationState::DRAFT
            msg << "<h4>This action will reserve a DOI</h4><hr/>"
            msg << "<ul>"
            msg << "<li>The DOI link will fail until #{effective_release_date}.</li>"
            msg << "<li>The record for your dataset is not visible, nor are your data files available until #{effective_release_date}.</li>"
          else
            # Should never get here, DataCite record changes are not relevant to Embargo::METADATA
            msg << "<h3>This action will not do anything.  The record for your dataset is not visible, and the DOI is already reserved.</h3>"
            msg << "<ul>"
          end

        else
          if dataset.publication_state == Databank::PublicationState::DRAFT
            msg << "<h4>This action will make your dataset public and create a DOI.</h4><hr/>"
          else
            msg << "<h4>This action will make your updates to your dataset record public.</h4>"
          end
          msg << "<ul>"
          msg << "<li>Your Illinois Data Bank dataset record will be publicly visible through search engines.</li>"
          msg << "<li>Your data files will be publicly available.</li>"
      end

      msg << "<li>You will be able to edit the description for the dataset to correct an error, but would need to contact the <a href='/help'>Research Data Service</a> if there is an error in the files that needs to be corrected.</li> "

      msg << "</ul></div>"

      msg
    end


  end

end
