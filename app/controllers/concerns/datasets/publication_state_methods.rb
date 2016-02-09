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

      # This method should only be called if there are DataCite relevant changes, including release date

      if !dataset.release_date || dataset.release_date <= Date.current()
        dataset.embargo = nil
      end

      msg = "<div class='confirm-modal-text'>"

      case dataset.embargo

        when Databank::PublicationState::FILE_EMBARGO
          if dataset.publication_state == Databank::PublicationState::DRAFT
            msg << "<h4>This action will make your record public and create a DOI.</h4><hr/>"
            msg << "<ul>"
            msg << "<li>Your Illinois Data Bank dataset record will be publicly visible through search engines.</li>"
            msg << "<li>Although the record for your dataset will be publicly visible, your data files will not be made available until #{dataset.release_date.iso8601}.</li>"

          else
            msg << "<h4>This action will make your updates to your dataset record public.</h4><hr/>"
            msg << "<ul>"
          end

        when Databank::PublicationState::METADATA_EMBARGO
          if dataset.publication_state == Databank::PublicationState::DRAFT
            msg << "<h4>This action will reserve a DOI</h4><hr/>"
            msg << "<ul>"
            msg << "<li>The DOI link will fail until #{dataset.release_date.iso8601}.</li>"
            msg << "<li>The record for your dataset is not visible, nor are your data files available until #{dataset.release_date.iso8601}.</li>"
          else
            # Should never get here, DataCite record changes are not relevant to METADATA_EMBARGO
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