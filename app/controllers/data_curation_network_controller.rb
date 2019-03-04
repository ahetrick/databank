class DataCurationNetworkController < ApplicationController

  before_action :set_invitee, only: [:my_account, :edit_account, :register]
  
  def index
    @search = nil
  end

  def accounts
    @accounts=Invitee.where(group: Databank::IdentityGroup::NETWORK_CURATOR)

    authorize! :manage, Invitee
  end

  def my_account
    unless @invitee
      redirect_to("/data_curation_network", notice: "Log in to curate datasets or manage your account. Contact the research data service for any needed assistance.") and return
    end
    authorize! :edit, @invitee
  end

  def add_account
    authorize! :manage, Invitee
    @invitee = Invitee.new
    render 'data_curation_network/account/add'
  end

  def edit_account
    authorize! :manage, Invitee
    unless @invitee
      redirect_to("/data_curation_network", notice: "error: unable to validate account identifier") and return
    end
    render 'data_curation_network/account/edit'
  end

  def register
    unless @invitee
      redirect_to("/data_curation_network", notice: "Log in to curate datasets or manage your account. Contact the research data service for any needed assistance.") and return
    end
    authorize! :edit, @invitee
  end

  def log_in
  end

  private

  def set_invitee
    @invitee = Invitee.find_by_key(params[:id])
    unless @invitee
      @invitee = Invitee.find(params[:invitee_id])
    end
    nil unless @invitee
  end

end
