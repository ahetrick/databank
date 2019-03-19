class InviteesController < ApplicationController
  before_action :set_invitee, only: [:show, :edit, :update, :destroy]

  # GET /invitees
  # GET /invitees.json
  def index
    @invitees = Invitee.all
  end

  # GET /invitees/1
  # GET /invitees/1.json
  def show
  end

  # GET /invitees/new
  def new
    @invitee = Invitee.new
  end

  # GET /invitees/1/edit
  def edit
  end

  # POST /invitees
  # POST /invitees.json
  def create
    @invitee = Invitee.new(invitee_params)

    authorize! :manage, @invitee

    respond_to do |format|

      if @invitee.save
        if @invitee.group == Databank::IdentityGroup::NETWORK_CURATOR
          format.html { redirect_to '/data_curation_network/accounts', notice: 'Invitee was successfully created.' }
          format.json { render :show, status: :created, location: @invitee }
        else
          format.html { redirect_to @invitee, notice: 'Invitee was successfully created.' }
          format.json { render :show, status: :created, location: @invitee }
        end
      else
        if @invitee.group == Databank::IdentityGroup::NETWORK_CURATOR
          format.html { redirect_to '/data_curation_network/accounts', notice: 'Error attempting to create invitee.' }
          format.json { render :show, status: :created, location: @invitee }
        else
          format.html { render :new }
          format.json { render json: @invitee.errors, status: :unprocessable_entity }
        end

      end
    end
  end

  # PATCH/PUT /invitees/1
  # PATCH/PUT /invitees/1.json
  def update
    authorize! :manage, @invitee
    if @invitee.group == Databank::IdentityGroup::NETWORK_CURATOR

        respond_to do |format|
          if @invitee.update(invitee_params)
            format.html { redirect_to "/data_curation_network/accounts", notice: 'Invitee was successfully updated.' }
            format.json { render :show, status: :ok, location: @invitee }
          else
            format.html { redirect_to "/data_curation_network/account/#{@invitee_id}/edit" }
            format.json { render json: @invitee.errors, status: :unprocessable_entity }
          end
        end
    else
      respond_to do |format|
        if @invitee.update(invitee_params)
          format.html { redirect_to @invitee, notice: 'Invitee was successfully updated.' }
          format.json { render :show, status: :ok, location: @invitee }
        else
          format.html { render :edit }
          format.json { render json: @invitee.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /invitees/1
  # DELETE /invitees/1.json
  def destroy
    authorize! :manage, @invitee
    @invitee.destroy
    respond_to do |format|
      format.html { redirect_to '/data_curation_network/accounts', notice: 'Invitee was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_invitee
      @invitee = Invitee.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def invitee_params
      params.require(:invitee).permit(:email, :group, :role, :expires_at)
    end
end
