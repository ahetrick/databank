class DatabankMailer < ActionMailer::Base
  default from: "databank@library.illinois.edu"

  def confirm_deposit(dataset_key)
    @dataset = Dataset.where(key: dataset_key).first
    if @dataset
      mail(to: [@dataset.depositor_email, @dataset.corresponding_creator_email], cc: 'databank@library.illinois.edu',  subject: '[Illinois Data Bank] Dataset successfully deposited')
    else
      Rails.logger.warn "Confirmation email not sent because dataset not found for key: #{dataset_key}."
    end
  end

  def confirm_deposit_update(dataset_key)
    @dataset = Dataset.where(key: dataset_key).first
    if @dataset
      mail(to: 'databank@library.illinois.edu', subject: '[Illinois Data Bank] Dataset successfully updated')
    else
      Rails.logger.warn "Update confirmation email not sent because dataset not found for key: #{dataset_key}."
    end
  end

  def contact_help(params)
    @params = params

    if @params['help-topic'] == 'Dataset Review'
      mail(from: @params['help-email'] , to:['databank@library.illinois.edu'], subject:'[Illinois Data Bank] Dataset Review Request')
    else
      mail(from: @params['help-email'] , to:['databank@library.illinois.edu'], subject:'[Illinois Data Bank] Help Request')
    end


  end

end