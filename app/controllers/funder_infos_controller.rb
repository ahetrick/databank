class FunderInfosController < ApplicationController
  before_action :set_funder_info, only: [:show, :edit, :update, :destroy]

  # GET /funder_infos
  # GET /funder_infos.json
  def index
    @funder_infos = FunderInfo.all
  end

  # GET /funder_infos/1
  # GET /funder_infos/1.json
  def show
  end

  # GET /funder_infos/new
  def new
    @funder_info = FunderInfo.new
  end

  # GET /funder_infos/1/edit
  def edit
  end

  # POST /funder_infos
  # POST /funder_infos.json
  def create
    @funder_info = FunderInfo.new(funder_info_params)

    respond_to do |format|
      if @funder_info.save
        format.html { redirect_to @funder_info, notice: 'Funder info was successfully created.' }
        format.json { render :show, status: :created, location: @funder_info }
      else
        format.html { render :new }
        format.json { render json: @funder_info.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /funder_infos/1
  # PATCH/PUT /funder_infos/1.json
  def update
    respond_to do |format|
      if @funder_info.update(funder_info_params)
        format.html { redirect_to @funder_info, notice: 'Funder info was successfully updated.' }
        format.json { render :show, status: :ok, location: @funder_info }
      else
        format.html { render :edit }
        format.json { render json: @funder_info.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /funder_infos/1
  # DELETE /funder_infos/1.json
  def destroy
    @funder_info.destroy
    respond_to do |format|
      format.html { redirect_to funder_infos_url, notice: 'Funder info was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_funder_info
    @funder_info = FunderInfo.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def funder_info_params
    params.require(:funder_info).permit(:code, :name, :identifier, :display_position, :identifier_scheme)
  end
end
