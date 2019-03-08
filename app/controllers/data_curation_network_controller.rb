class DataCurationNetworkController < ApplicationController

  before_action :set_invitee, only: [:my_account, :edit_account]
  
  def index
    @drafts = Dataset.where(data_curation_network: true, publication_state: Databank::PublicationState::DRAFT)
    @nondrafts = Dataset.where(data_curation_network: true).where.not(publication_state: Databank::PublicationState::DRAFT)
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
    @invitee.expires_at = Time.now + 3.months
    @invitee.group = Databank::IdentityGroup::NETWORK_CURATOR
    @invitee.role = Databank::UserRole::REVIEWER
    @group_arr = Array.new
    @group_arr.push(Databank::IdentityGroup::NETWORK_CURATOR)
    @role_arr = Array.new
    @role_arr.push(Databank::UserRole::REVIEWER)
    render 'data_curation_network/account/add'
  end

  def edit_account
    unless @invitee
      redirect_to("/data_curation_network", notice: "error: unable to validate account identifier") and return
    end
    authorize! :manage, @invitee
    @group_arr = Array.new
    @group_arr.push(Databank::IdentityGroup::NETWORK_CURATOR)
    @role_arr = Array.new
    @role_arr.push(Databank::UserRole::REVIEWER)
    render 'data_curation_network/account/edit'
  end

  def register
  end

  def log_in
  end

  private

  def set_invitee
    @invitee = Invitee.find(params[:id])
    unless @invitee
      @invitee = Invitee.find(params[:invitee_id])
    end
    nil unless @invitee
  end

end
