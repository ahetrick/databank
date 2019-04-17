# frozen_string_literal: true

module Complete
  extend ActiveSupport::Concern

  class_methods do
    # making completion_check a class method with passed-in dataset, so it can be used by controller before save
    def completion_check(dataset, current_user)
      response = "An unexpected exception was raised and logged during completion check."

      begin
        validation_error_messages = []
        validation_error_message = ""

        datafilesArr = []

        validation_error_messages << "title" if dataset.title.blank?

        validation_error_messages << "at least one creator" if dataset.creators.count < 1

        validation_error_messages << "license" if dataset.license.blank?

        contact = nil
        dataset.creators.each do |creator|
          contact = creator if creator.is_contact?
        end

        dataset.creators.each do |creator|
          if !creator.email || creator.email == ""
            validation_error_messages << "an email address for all creators"
          elsif creator.email.include?("@illinois.edu")
            netid = creator.email.split("@").first

            creator_record = nil

            # check to see if netid is found, to prevent email system errors
            begin
              creator_record = open("http://quest.grainger.uiuc.edu/directory/ed/person/#{netid}").read
            rescue OpenURI::HTTPError => err
              validation_error_messages << "a valid email address for #{creator.given_name} #{creator.family_name} (please check and correct the netid)"
            end

          end
        end

        dataset.creators.each do |creator|
          if creator.type_of == Databank::CreatorType::PERSON && (!creator.given_name || creator.given_name == "")
            validation_error_messages << "at least one given name for author(s)"
            break
          end
        end

        dataset.creators.each do |creator|
          if creator.type_of == Databank::CreatorType::PERSON && !creator.given_name || creator.given_name == ""
            validation_error_messages << "a family name for author(s)"
            break
          end
        end

        dataset.creators.each do |creator|
          if creator.type_of == Databank::CreatorType::INSTITUTION && !creator.institution_name || creator.institution_name == ""
            validation_error_messages << "a name for institution(s)"
            break
          end
        end

        validation_error_messages << "select primary contact from author list" unless contact

        if current_user
          if (current_user.role != "admin") && (dataset.release_date && (dataset.release_date > (Date.current + 1.year)))
            validation_error_messages << "a release date no more than one year in the future"
          end
        end

        if dataset.license && dataset.license == "license.txt"
          has_file = false
          dataset.datafiles&.each do |datafile|
            has_file = true if datafile.bytestream_name&.casecmp("license.txt")&.zero?
          end

          validation_error_messages << "a license file named license.txt or a different license selection" unless has_file

        end

        if dataset.identifier && dataset.identifier != ""
          dupcheck = Dataset.where(identifier: dataset.identifier)
          validation_error_messages << "a unique DOI" if dupcheck.count > 1
        end

        if dataset.datafiles.count < 1
          validation_error_messages << "at least one file"
        else
          dataset.datafiles.each do |datafile|
            datafilesArr << datafile.bytestream_name
          end

          firstDup = datafilesArr.find {|e| datafilesArr.count(e) > 1 }

          validation_error_messages << "no duplicate filenames (#{firstDup})" if firstDup

        end

        if dataset.embargo && [Databank::PublicationState::Embargo::FILE, Databank::PublicationState::Embargo::METADATA].include?(dataset.embargo)
          if !dataset.release_date || dataset.release_date <= Date.current
            validation_error_messages << "a future release date for delayed publication (embargo) selection"
          end

        else
          if dataset.release_date && dataset.release_date > Date.current
            validation_error_messages << "a delayed publication (embargo) selection for a future release date"
          end
        end

        validation_error_messages << "identifier to import" if dataset.is_import? && !dataset.identifier
      rescue Exception => exception
        # temporary debugging strategy
        # I expect something terrible is happening here at runtime,
        # and my overall rescue of Standard Exception
        # is not catching anything.
        # This is totally the desparate measure it looks like.

        Rails.logger.warn exception.to_yaml

        exception_string = "*** Standard Error caught in application_controller.rb on #{IDB_CONFIG[:root_url_text]} ***\nclass: #{exception.class}\nmessage: #{exception.message}\n"
        exception_string << Time.now.utc.iso8601

        exception_string << "\nstack:\n"
        exception.backtrace.each do |line|
          exception_string << line
          exception_string << "\n"
        end

        Rails.logger.warn(exception_string)

        exception_string << "\nCurrent User: #{current_user.name} | #{current_user.email}" if current_user

        notification = DatabankMailer.error(exception_string)
        notification.deliver_now

        raise exception
      else
        if !validation_error_messages.empty?
          validation_error_message << "Required elements for a complete dataset missing: "
          validation_error_messages.each_with_index do |m, i|
            validation_error_message << ", " if i > 0
            validation_error_message << m
          end
          validation_error_message << "."

          response = validation_error_message
        else
          response = "ok"
        end
      ensure
        return response || "error"
      end
    end
  end
end
