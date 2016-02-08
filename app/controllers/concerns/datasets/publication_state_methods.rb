module Datasets

  module PublicationStateMethods
    extend ActiveSupport::Concern

    def send_deposit_confirmation_email (old_state, dataset)
      Rails.logger.warn "inside send_deposit_confirmation_email method for old_state #{old_state}, new_state: #{dataset.publication_state}, dataset: #{dataset.key}"
    end

    def deposit_confirmation_notice (old_state, dataset)
      %Q[Dataset was successfully published and the DataCite DOI minted is #{dataset.identifier}.<br/>The persistent link to this dataset is now <a href = "http://dx.doi.org/#{dataset.identifier}">http://dx.doi.org/#{dataset.identifier}</a>.<br/>There may be a delay before the persistent link will be in effect.  If this link does not redirect to the dataset immediately, try again in an hour.]

    end


    def publish_modal_msg (dataset)

      # This should only be relevant if there are DataCite relevant changes, including release date

      if !dataset.release_date || dataset.release_date <= Date.current()
        dataset.embargo = nil
      end

      msg = ""

      case dataset.embargo

        when Databank::PublicationState::FILE_EMBARGO
          if dataset.publication_state == Databank::PublicationState::DRAFT
            msg << "This action will make your record public and create a DOI. Information for your dataset in the Illinois Data Bank will be publicly visible through several search engines. Although the record for your dataset will be publically visible, your data files will not be made available until #{dataset.release_date.iso8601}. "
          else
            msg << "This action will make your updates to your dataset record public. "
          end

        when Databank::PublicationState::METADATA_EMBARGO
          if dataset.publication_state == Databank::PublicationState::DRAFT
            msg << "This action will reserve a DOI, but the DOI link will fail until #{dataset.release_date.iso8601}.  The record for your dataset is not visible, nor are your data files available until #{dataset.release_date.iso8601}. "
          else
            # Should never get here, DataCite record changes are not relevant to METADATA_EMBARGO
            "This action will not do anything.  The record for your dataset is not visible, and the DOI is already reserved. "
          end

        else
          if dataset.publication_state == Databank::PublicationState::DRAFT
            msg << "This action will make your dataset public and create a DOI. "
          else
            msg << "This action will make your updates to your dataset public. "
          end
      end

      msg << "You will be able to edit the description for the dataset to correct an error, but you would need to contact the <a href='http://researchdataservice.illinois.edu/contact-us'>Research Data Service</a> directly if there is an error in the files that needs to be corrected. "

      msg
    end

    def visibility_msg(dataset)
      msg = ""
      case dataset.publication_state
        when Databank::PublicationState::FILE_EMBARGO
          msg = "Files associated with this dataset are unavailable. Please contact us for more information."
        when Databank::PublicationState::METADATA_EMBARGO
          msg = "This dataset will be made available on #{@dataset.release_date.iso8601}"
      end
      msg
    end
  end
end


# def change_publication_state(new_state)
#   @dataset.publication_state |= PublicationState::DRAFT
#   unless (new_state == @dataset.publication_state)
#
#     case new_state
#       when PublicationState::DRAFT
#         case @dataset.publication_state
#
#           when PublicationState::RELEASED
#             #TODO
#           when PublicationState::STANDARD_EMBARGO
#             #TODO
#           when PublicationState::INVISIBLE_EMBARGO
#             #TODO
#           when PublicationState::TOMBSTONE
#             #TODO
#         end
#
#       when PublicationState::RELEASED
#         case @dataset.publication_state
#           when PublicationState::DRAFT
#             #TODO
#           when PublicationState::STANDARD_EMBARGO
#             #TODO
#           when PublicationState::INVISIBLE_EMBARGO
#             #TODO
#           when PublicationState::TOMBSTONE
#             #TODO
#         end
#
#       when PublicationState::STANDARD_EMBARGO
#         case @dataset.publication_state
#           when PublicationState::DRAFT
#             #TODO
#           when PublicationState::RELEASED
#             #TODO
#           when PublicationState::INVISIBLE_EMBARGO
#             #TODO
#           when PublicationState::TOMBSTONE
#             #TODO
#         end
#
#       when PublicationState::INVISIBLE_EMBARGO
#         case @dataset.publication_state
#           when PublicationState::DRAFT
#             #TODO
#           when PublicationState::RELEASED
#             #TODO
#           when PublicationState::STANDARD_EMBARGO
#             #TODO
#           when PublicationState::TOMBSTONE
#             #TODO
#         end
#
#       when PublicationState::TOMBSTONE
#         case @dataset.publication_state
#           when PublicationState::DRAFT
#             #TODO
#           when PublicationState::RELEASED
#             #TODO
#           when PublicationState::STANDARD_EMBARGO
#             #TODO
#           when PublicationState::INVISIBLE_EMBARGO
#             #TODO
#
#         end
#       end
#     end
#   end
# end