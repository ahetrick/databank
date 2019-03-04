class DataCurationNetworkController < ApplicationController

  before_action :set_account, only: [:my_account, :edit_account, :register]
  
  def index
    @search = nil
  end

  def accounts
    @accounts=Invitee.where(group: Databank::IdentityGroup::NETWORK_CURATOR)

    authorize! :manage, Invitee
  end

  def my_account
    unless @account
      redirect_to("/data_curation_network", notice: "Log in to curate datasets or manage your account. Contact the research data service for any needed assistance.") and return
    end
    authorize! :edit, @account
  end

  def add_account
    authorize! :manage, Invitee
    @account = Invitee.new
    render 'data_curation_network/account/add'
  end

  def edit_account
    authorize! :manage, Invitee
    unless @account
      redirect_to("/data_curation_network", notice: "error: unable to validate account identifier") and return
    end
    render 'data_curation_network/account/edit'
  end

  def register
    unless @account
      redirect_to("/data_curation_network", notice: "Log in to curate datasets or manage your account. Contact the research data service for any needed assistance.") and return
    end
    authorize! :edit, @account
  end

  def log_in
  end

  private

  def set_account
    @account = Invitee.find_by_key(params[:id])
    unless @account
      @account = Invitee.find(params[:invitee_id])
    end
    nil unless @dataset
  end

end
