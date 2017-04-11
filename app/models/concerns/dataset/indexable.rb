module Indexable
  extend ActiveSupport::Concern

  def visibility
    return_string = ""
    case self.hold_state
      when Databank::PublicationState::TempSuppress::METADATA
        return_string = "Metadata and Files Temporarily Suppressed"
      when Databank::PublicationState::TempSuppress::FILE
        case self.publication_state
          when Databank::PublicationState::DRAFT
            return_string = "Draft"
          when Databank::PublicationState::Embargo::FILE
            return_string = "Metadata Published, Files Publication Delayed (Embargoed)"
          when Databank::PublicationState::Embargo::METADATA
            return_string = "Metadata and Files Publication Delayed (Embargoed)"
          when Databank::PublicationState::PermSuppress::FILE
            return_string = "Metadata Published, Files Withdrawn"
          when Databank::PublicationState::PermSuppress::METADATA
            return_string = "Metadata and Files Withdrawn"
          else
            return_string = "Metadata Published, Files Temporarily Suppressed"
        end

      else
        case self.publication_state
          when Databank::PublicationState::DRAFT
            return_string = "Draft"
          when Databank::PublicationState::RELEASED
            return_string = "Metadata and Files Published"
          when Databank::PublicationState::Embargo::FILE
            return_string = "Metadata Published, Files Publication Delayed (Embargoed)"
          when Databank::PublicationState::Embargo::METADATA
            return_string = "Metadata and Files Publication Delayed (Embargoed)"
          when Databank::PublicationState::PermSuppress::FILE
            return_string = "Metadata Published, Files Withdrawn"
          when Databank::PublicationState::PermSuppress::METADATA
            return_string = "Metadata and Files Withdrawn"
          else
            #should never get here
            return_string = "Unknown, please contact the Research Data Service"
        end
    end

    if self.new_record?
      return_string = "Unsaved Draft"
    end

    return_string
  end

  def self.visibility_name_from_code(code)

    case code
      when 'released'
        return 'Metadata and Files Published'
      when 'draft'
        return 'Draft'
      when 'new'
        return 'Unsaved Draft'
      when 'suppressed_mf'
        return 'Metadata and Files Temporarily Suppressed'
      when 'suppressed_f'
        return 'Metadata Published, Files Temporarily Suppressed'
      when 'embargoed_mf'
        return 'Metadata and Files Publication Delayed (Embargoed)'
      when 'embargoed_f'
        return 'Metadata Published, Files Publication Delayed (Embargoed)'

      when 'withdrawn_mf'
        return 'Metadata and Files Withdrawn'
      when 'withdrawn_f'
        return 'Metadata Published, Files Withdrawn'
      else
        return 'Error: publication state not found'
    end

  end

  def visibility_code
    return_string = ""
    case self.hold_state
      when Databank::PublicationState::TempSuppress::METADATA
        return_string = 'suppressed_mf'
      when Databank::PublicationState::TempSuppress::FILE
        case self.publication_state
          when Databank::PublicationState::DRAFT
            return_string = 'draft'
          when Databank::PublicationState::Embargo::FILE
            return_string = 'embargoed_f'
          when Databank::PublicationState::Embargo::METADATA
            return_string = 'embargoed_mf'
          when Databank::PublicationState::PermSuppress::FILE
            return_string = 'withdrawn_f'
          when Databank::PublicationState::PermSuppress::METADATA
            return_string = 'withdrawn_mf'
          else
            return_string = 'suppressed_f'
        end

      else
        case self.publication_state
          when Databank::PublicationState::DRAFT
            return_string = 'draft'
          when Databank::PublicationState::RELEASED
            return_string = 'released'
          when Databank::PublicationState::Embargo::FILE
            return_string = 'embargoed_f'
          when Databank::PublicationState::Embargo::METADATA
            return_string = 'embargoed_mf'
          when Databank::PublicationState::PermSuppress::FILE
            return_string = 'withdrawn_f'
          when Databank::PublicationState::PermSuppress::METADATA
            return_string = 'withdrawn_mf'
          else
            #should never get here
            return_string = "unknown"
        end
    end

    if self.new_record?
      return_string = 'new'
    end

    return_string
  end


  def self.license_name_from_code(code)

    if ['unselected', 'custom'].include?(code)
      return code

    else
      licenses = LICENSE_INFO_ARR.select{|license| license.code == code}
      if licenses && licenses.length > 0
        return licenses[0].name
      else
        return code
      end

    end


  end

  def self.funder_name_from_code(code)

    if code == 'other'
      return "Other"
    else
      funders = FUNDER_INFO_ARR.select{|funder| funder.code == code}
      if funders && funders.length > 0
        return funders[0].name
      else
        return 'funder not found'
      end
    end

  end

  def funder_names
    Funder.where(dataset_id: self.id).pluck(:name)
  end

  def funder_codes
    Funder.where(dataset_id: self.id).pluck(:code)
  end

  def funder_names_fulltext
    self.funder_names.join(" ").to_s
  end

  def grant_numbers
    Funder.where(dataset_id: self.id).pluck(:grant)
  end

  def grant_numbers_fulltext
    self.grant_numbers.join(" ")
  end

  def creator_names
    return_arr = Array.new
    self.creators.each do |creator|
      return_arr << creator.display_name
    end
    return_arr
  end

  def creator_names_fulltext
    self.creator_names.join(" ")
  end


  def filenames
    return_arr = Array.new
    self.datafiles.each do |datafile|
      return_arr << datafile.bytestream_name
    end
    return_arr
  end

  def filenames_fulltext
    self.filenames.join(" ")
  end

  def self.pubstate_name_from_code(code)
    case code
      when Databank
        return "draft"
      else
        return "not draft"
    end
  end
  def datafile_extensions
    return_arr = Array.new
    self.datafiles.each do |datafile|
      return_arr << datafile.file_extension
    end
    return_arr
  end

  def datafile_extensions_fulltext
    self.datafile_extensions.join(" ")
  end

  def release_datetime
    if self.release_date && self.release_date != ""
      return DateTime.new(self.release_date.year, self.release_date.mon, self.release_date.mday)
    else
      return DateTime.new(0,0,0)
    end

  end


  def self.citation_report(search, request_url, current_user)

    report_text = ""

    75.times do
      report_text = report_text + "="
    end

    report_text = report_text + "\nIllinois Data Bank\nDatasets Report, generated #{Date.current.iso8601}"
    if current_user && current_user.username
      report_text = report_text + "by #{current_user}"
    end
    report_text = report_text + "\nQuery URL: #{request_url}\n"

    75.times do
      report_text = report_text + "="
    end

    report_text = report_text + "\n"

    search.each_hit_with_result do |hit, dataset|

      report_text = report_text + "\n\n#{dataset.plain_text_citation}"
      if dataset.funders.count > 0
        dataset.funders.each do |funder|
          report_text = report_text + "\nFunder: #{funder.name}"
          if funder.grant && funder.grant != ""
            report_text = report_text + ", Grant: #{funder.grant}"
          end

        end
      end
      report_text = report_text + "\nDownloads: #{dataset.total_downloads}\n"
      75.times do
        report_text = report_text + "-"
      end
    end

    report_text

  end
end
