class ChangelogsController < ApplicationController

  protect_from_forgery
  before_action :set_changes, only: [:edit, :update]

  def edit
    authorize! :edit, @changes
  end

  def update
    authorize! :update, @changes

    @changes.each do |change|
      Rails.logger.warn change.to_yaml
    end

  end

  private

  def set_dataset
    @dataset = Dataset.find_by_key(params[:id])
    raise ActiveRecord::RecordNotFound unless @dataset
  end

  def set_changes
    set_dataset
    @changes = Audited::Adapters::ActiveRecord::Audit.where("(auditable_type=? AND auditable_id=?) OR (associated_id=?)", 'Dataset', @dataset.id, @dataset.id)
  end
end