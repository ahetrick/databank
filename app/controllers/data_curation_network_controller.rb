class DataCurationNetworkController < ApplicationController

  def index
    @drafts = Dataset.where(data_curation_network: true).where(publication_state: Databank::PublicationState::DRAFT)
    @nondrafts = Dataset.where(data_curation_network: true).where.not(publication_state: Databank::PublicationState::DRAFT)
  end

  def accounts
    @accounts=Invitee.where(group: Databank::IdentityGroup::NETWORK_CURATOR)
    authorize! :manage, Invitee
  end

  def my_account
    unless current_user&.email
      redirect_to("/data_curation_network", notice: "Log in to curate datasets or manage your account. Contact the research data service for any needed assistance.") and return
    end
    @identity = Identity.find_by_email(current_user.email)
    unless @identity
      redirect_to("/data_curation_network", notice: "Unable to authorize account update. Contact the research data service for any needed assistance.") and return
    end
  end

  def update_identity

    Rails.logger.warn params

    password_notice = nil

    @identity = Identity.find(params[:id])

    authorize! :edit, @identity

    if params[:identity][:name] != ''
      @identity.name = params[:identity][:name]
    end

    if params[:password] != '' && params[:password_confirmation] != '' && params[:password] == params[:password_confirmation]
      @identity.password = params[:password]
      @identity.password_confirmation = params[:password]
    end

    respond_to do |format|
      if @identity.save
        format.html { redirect_to "/data_curation_network/my_account", notice: "Account was successfully updated." }
        format.json { render :show, status: :ok, location: @identity }
      else
        @identity.errors.each do |error|
          Rails.logger.warn error.to_yaml
        end
        format.html { redirect_to "/data_curation_network", notice: 'Error encountered while attempting to update account.' }
        format.json { render json: @identity.errors, status: :unprocessable_entity }
      end
    end

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
    set_invitee
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
    unless @invitee
      if current_user && current_user.role == Databank::UserRole::REVIEWER
        @invitee = Invitee.find_by_email(current_user.email)
      end
    end
    nil unless @invitee
  end

end
