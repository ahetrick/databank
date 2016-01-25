class DatabankMailer < ActionMailer::Base
  default from: "no-reply@databank.illinois.edu"

  def confirm_deposit(dataset_key)
    @dataset = Dataset.where(key: dataset_key)
    if @dataset
      mail(to: @dataset.depositor_email, subject: 'Dataset Publication Confirmation')
    else
      Rails.logger.warn "Confirmation email not sent because dataset not found for key: #{dataset_key}."
    end



  end

end