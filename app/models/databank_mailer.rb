class DatabankMailer < ActionMailer::Base
  default from: "databank@library.illinois.edu"

  def confirm_deposit(dataset_key)
    @dataset = Dataset.where(key: dataset_key).first
    if @dataset
      mail(to: [@dataset.depositor_email, @dataset.corresponding_creator_email], subject: '[Illinois Data Bank] Dataset successfully deposited')
    else
      Rails.logger.warn "Confirmation email not sent because dataset not found for key: #{dataset_key}."
    end

  end

end