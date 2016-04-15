module MessageText
  extend ActiveSupport::Concern

  class_methods do

    def deposit_confirmation_notice(old_state, dataset)

      new_state = dataset.publication_state

      case old_state
        when Databank::PublicationState::DRAFT
          case new_state
            when Databank::PublicationState::RELEASED
              return %Q[Dataset was successfully published and the DataCite DOI is #{dataset.identifier}.<br/>The persistent link to this dataset is now <a href = "https://doi.org/#{dataset.identifier}">https://doi.org/#{dataset.identifier}</a>.<br/>There may be a delay before the persistent link will be in effect.  If this link does not redirect to the dataset immediately, try again in an hour.]

            when Databank::PublicationState::Embargo::METADATA
              return %Q[DataCite DOI #{dataset.identifier} successfully reserved.<br/>The persistent link to this dataset will be <a href = "https://doi.org/#{dataset.identifier}">https://doi.org/#{dataset.identifier}</a> starting #{dataset.release_date}.]

            when Databank::PublicationState::Embargo::FILE
              return %Q[Dataset record was successfully published and the DataCite DOI is #{dataset.identifier}.<br/>Although the record for your dataset will be publicly visible, your data files will not be made available until #{dataset.release_date.iso8601}.<br/>The persistent link to this dataset is now <a href = "https://doi.org/#{dataset.identifier}">https://doi.org/#{dataset.identifier}</a>.<br/>There may be a delay before the persistent link will be in effect.  If this link does not redirect to the dataset immediately, try again in an hour.]
            else
              return %Q[Unexpected error, please contact the <a href="/help">Research Data Service Team</help>.]
          end

        when Databank::PublicationState::RELEASED
          case new_state
            when Databank::PublicationState::RELEASED
              return %Q[Dataset record changes have been successfully published.]

            when Databank::PublicationState::Embargo::METADATA
              return %Q[Placeholder metadata has replaced previously published metadata for this DataCite DOI #{dataset.identifier}.<br/>The persistent link to this dataset will be <a href = "https://doi.org/#{dataset.identifier}">https://doi.org/#{dataset.identifier}</a> starting #{dataset.release_date}.]

            when Databank::PublicationState::Embargo::FILE
              return %Q[Dataset record changes have been was successfully published.<br/>Although the record for your dataset will be publicly visible, your data files will not be made available until #{dataset.release_date.iso8601}.]
            else
              return %Q[Unexpected error, please contact the <a href="/help">Research Data Service Team</help>.]
          end

        when Databank::PublicationState::Embargo::METADATA
          case new_state
            when Databank::PublicationState::RELEASED
              return %Q[Dataset was successfully published and the DataCite DOI is #{dataset.identifier}.<br/>The persistent link to this dataset is <a href = "https://doi.org/#{dataset.identifier}">https://doi.org/#{dataset.identifier}</a>.<br/>There may be a delay before the persistent link will be in effect.  If this link does not redirect to the dataset immediately, try again in an hour.]

            when Databank::PublicationState::Embargo::METADATA
              return %Q[No changes have been published.<br/>The persistent link to this dataset will be <a href = "https://doi.org/#{dataset.identifier}">https://doi.org/#{dataset.identifier}</a> starting #{dataset.release_date}.]

            when Databank::PublicationState::Embargo::FILE
              return %Q[Dataset record was successfully published and the DataCite DOI is #{dataset.identifier}.<br/>Although the record for your dataset will be publicly visible, your data files will not be made available until #{dataset.release_date.iso8601}.<br/>The persistent link to this dataset is now <a href = "https://doi.org/#{dataset.identifier}">https://doi.org/#{dataset.identifier}</a>.<br/>There may be a delay before the persistent link will be in effect.  If this link does not redirect to the dataset immediately, try again in an hour.]
            else
              return %Q[Unexpected error, please contact the <a href="/help">Research Data Service Team</help>.]
          end

        when Databank::PublicationState::Embargo::FILE

          case new_state
            when Databank::PublicationState::RELEASED
              return %Q[Dataset was successfully published and files are publically available.]

            when Databank::PublicationState::Embargo::METADATA
              return %Q[A placeholder record has replaced the previously published record for this DataCite DOI #{dataset.identifier}.<br/>The persistent link to this dataset is <a href = "https://doi.org/#{dataset.identifier}">https://doi.org/#{dataset.identifier}</a> starting #{dataset.release_date}.]

            when Databank::PublicationState::Embargo::FILE
              return %Q[Dataset record changes have been was successfully published.<br/>Although the record for your dataset will be publicly visible, your data files will not be made available until #{dataset.release_date.iso8601}.]
            else
              return %Q[Unexpected error, please contact the <a href="/help">Research Data Service Team</help>.]
          end

        when Databank::PublicationState::PermSuppress::FILE
          case new_state
            when Databank::PublicationState::RELEASED
              return %Q[Dataset record changes have been successfully published.]

            when Databank::PublicationState::Embargo::METADATA
              return %Q[A placeholder record has replaced the previously published record for this DataCite DOI #{dataset.identifier}.<br/>The descriptive record for your dataset and your files will be publicly available #{dataset.release_date.iso8601}.]

            when Databank::PublicationState::Embargo::FILE
              return %Q[Dataset record changes have been successfully published.<br/>Although the record for your dataset is publicly visible, your data files will not be made available until #{dataset.release_date.iso8601}.]
            else
              return %Q[Unexpected error, please contact the <a href="/help">Research Data Service Team</help>.]
          end


        else
          Rails.logger.warn "unexpected state during publish for dataset #{dataset.key}."
          return %Q[Changes to this dataset's public record have been made effective.]
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
          elsif [Databank::PublicationState::Embargo::FILE, Databank::PublicationState::RELEASED].include?(dataset.publication_state)
            msg << "<h3>This action will remove your dataset from public availability.</h3>"
            msg << "<ul>"
            msg << "<li>The DOI link will resolve to an EZID tombestone page until #{effective_release_date}.</li>"
            msg << "<li>The record for your dataset is not visible, nor are your data files available until #{effective_release_date}.</li>"
          else
            msg << "<h4>Unexpected Error: Please contact the <a href='/help'>Research Data Service Team</a>.</h4><hr/>"
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

      msg << "<li>You will be able to edit the description for the dataset, but would need to contact the <a href='/help'>Research Data Service</a> if you need to change, update, or add files for any reason.</li> "

      msg << "</ul></div>"

      msg
    end


  end

end
