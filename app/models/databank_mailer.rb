require 'open-uri'

class DatabankMailer < ActionMailer::Base
  default from: "databank@library.illinois.edu"

  def confirm_deposit(dataset_key)
    @dataset = Dataset.where(key: dataset_key).first

    subject = prepend_system_code("Illinois Data Bank] Dataset successfully deposited (#{@dataset.identifier})")


    if @dataset
      to_array = Array.new

      to_array << @dataset.depositor_email

      @dataset.creators.each do |creator|
        to_array << creator.email
      end

      mail(to: to_array , cc: 'databank@library.illinois.edu', subject: subject)
    else
      Rails.logger.warn "Confirmation email not sent because dataset not found for key: #{dataset_key}."
    end
  end

  def confirm_deposit_update(dataset_key)

    subject = prepend_system_code("Illinois Data Bank] Dataset successfully updated (#{@dataset.identifier})")


    @dataset = Dataset.where(key: dataset_key).first
    if @dataset
      mail(to: 'databank@library.illinois.edu', subject: subject)
    else
      Rails.logger.warn "Update confirmation email not sent because dataset not found for key: #{dataset_key}."
    end
  end

  def contact_help(params)

    subject = prepend_system_code('Illinois Data Bank] Help Request')
    @params = params
    if @params['help-topic'] == 'Dataset Consultation'
      subject = prepend_system_code('Illinois Data Bank] Dataset Consultation Request')
    end
    mail(from: @params['help-email'], to: ['databank@library.illinois.edu', @params['help-email']], subject: subject)

  end

  def dataset_incomplete_1m(dataset_key)

    subject = prepend_system_code('Illinois Data Bank] Incomplete dataset deposit')

    @dataset = Dataset.where(key: dataset_key).first
    if @dataset
      mail(to: dataset.depositor_email, cc: 'databank@library.illinois.edu', subject: subject)
    else
      Rails.logger.warn "Dataset incomplete 1m email not sent because dataset not found for key: #{dataset_key}."
    end
  end

  def embargo_approaching_1m(dataset_key)

    subject = prepend_system_code('Illinois Data Bank] Dataset release date approaching')

    @dataset = Dataset.where(key: dataset_key).first
    if @dataset
      mail(to: @dataset.depositor_email, cc: 'databank@library.illinois.edu', subject: subject)
    else
      Rails.logger.warn "Embargo approaching 1m email not sent because dataset not found for key: #{dataset_key}."
    end
  end

  def embargo_approaching_1w(dataset_key)

    subject = prepend_system_code('Illinois Data Bank] Dataset release date approaching')

    @dataset = Dataset.where(key: dataset_key).first
    if @dataset
      mail(to: @dataset.depositor_email, cc: 'databank@library.illinois.edu', subject: subject )
    else
      Rails.logger.warn "Embargo approaching 1w email not sent because dataset not found for key: #{dataset_key}."
    end
  end

  def error(error_text)
    @error_text = error_text

    subject = prepend_system_code('Illinois Data Bank] System Error')

    mail(to: "#{IDB_CONFIG[:tech_error_mail_list]}", subject: subject)
  end

  def ezid_warnings(report)
    @report = report

    subject = prepend_system_code('Illinois Data Bank] EZID Differences Report')

    mail(to: "#{IDB_CONFIG[:tech_error_mail_list]}", subject: subject)
  end

  def backup_report()

    @expected_path = "#{IDB_CONFIG[:databank_backup_root]}/#{Date.current}.sql"

    @is_ok = File.exists?(@expected_path)

    subject = nil

    if @is_ok
      subject = prepend_system_code("Illinois Data Bank] Backup exists for #{Date.current}")
    else
      subject = prepend_system_code("Illinois Data Bank] Backup NOT FOUND for #{Date.current}")
    end

    mail(to: "#{IDB_CONFIG[:tech_error_mail_list]}", subject: subject)

  end

  def confirmation_not_sent(dataset_key, err)
    subject = prepend_system_code('Illinois Data Bank] Dataset confirmation email not sent')

    @err = err
    @dataset = Dataset.where(key: dataset_key).first
    if @dataset
      mail(to: 'databank@library.illinois.edu', subject: subject )
    else
      Rails.logger.warn "Confirmation email not sent email not sent because dataset not found for key: #{dataset_key}."
    end

  end


  def link_report()
    subject = prepend_system_code('Illinois Data Bank] Related Materials Links Status Report')

    datasets = Dataset.where(publication_state: [Databank::PublicationState::RELEASED, Databank::PublicationState::Embargo::FILE, Databank::PublicationState::TempSuppress::FILE, Databank::PublicationState::PermSuppress::FILE]).where(is_test: false)

    @report = "<table border='1'><tr><th>DOI</th><th>Dataset_URL</th><th>Material_Type</th><th>Relationship</th><th>Material_URL</th><th>Status_Code</th></tr>"

    datasets.each do |dataset|

      dataset.related_materials.each do |material|

        datacite_arr = Array.new

        if material.datacite_list && material.datacite_list != ''
          datacite_arr = material.datacite_list.split(',')
        end

        datacite_arr.each do |relationship|

          if ['IsPreviousVersionOf','IsNewVersionOf'].exclude?(relationship)

            if material.link && material.link != ""

              the_status = "error"


              begin
                io_thing = open(material.link)

                # The text of the status code is in [1]
                the_status = io_thing.status[0]

              rescue OpenURI::HTTPError => the_error

                the_status = the_error.io.status[0] # => 3xx, 4xx, or 5xx

              rescue Errno::ENOENT => err

                the_status = "malformed url"

              end

            end

            @report = @report + "<tr><td>#{dataset.identifier}</td><td>#{IDB_CONFIG[:root_url_text]}/datasets/#{dataset.key}</td><td>#{material.selected_type}</td><td>#{relationship}</td><td>#{material.link}</td><td>#{the_status}</td></tr>"

          end

        end

      end

    end

    @report = @report + "</table>"

    mail(to: "#{IDB_CONFIG[:tech_error_mail_list]}", subject: subject)

  end


  def prepend_system_code(subject)
    # Rails.logger.warn IDB_CONFIG[:root_url_text]
    if IDB_CONFIG[:root_url_text].include?("dev")
      subject.prepend("[DEV: ")
    elsif IDB_CONFIG[:root_url_text].include?("localhost")
      subject.prepend("[LOCAL: ")
    elsif IDB_CONFIG[:root_url_text].include?("pilot")
      subject.prepend("[PILOT: ")
    else
      subject.prepend("[")
    end
    return subject
  end



end

