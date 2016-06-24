class DatabankMailer < ActionMailer::Base
  default from: "databank@library.illinois.edu"

  def confirm_deposit(dataset_key)
    @dataset = Dataset.where(key: dataset_key).first

    subject = prepend_system_code('Illinois Data Bank] Dataset successfully deposited')


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

    subject = prepend_system_code('Illinois Data Bank] Dataset successfully updated')


    @dataset = Dataset.where(key: dataset_key).first
    if @dataset
      mail(to: 'databank@library.illinois.edu', subject: subject)
    else
      Rails.logger.warn "Update confirmation email not sent because dataset not found for key: #{dataset_key}."
    end
  end

  def contact_help(params)

    subject = prepend_system_code('Illinois Data Bank] Dataset Consultation Request')

    @params = params

    if @params['help-topic'] == 'Dataset Consultation'
      mail(from: @params['help-email'], to: ['databank@library.illinois.edu'], subject: subject)
    else
      mail(from: @params['help-email'], to: ['databank@library.illinois.edu'], subject: subject)
    end
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

  def prepend_system_code(subject)
    Rails.logger.warn IDB_CONFIG[:root_url_text]
    if IDB_CONFIG[:root_url_text].include?("dev")
      subject.prepend("[DEV: ")
    elsif IDB_CONFIG[:root_url_text].include?("localhost")
      subject.prepend("[LOCAL: ")
    else
      subject.prepend("[")
    end
    return subject
  end

end

