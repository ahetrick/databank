class DeckfilesController < ApplicationController
  before_action :set_deckfile, only: [:show, :edit, :update, :destroy, :download]

  # GET /deckfiles
  # GET /deckfiles.json
  def index
    @deckfiles = Deckfile.all
  end

  # GET /deckfiles/1
  # GET /deckfiles/1.json
  def show
  end

  # GET /deckfiles/new
  def new
    @deckfile = Deckfile.new
  end

  # GET /deckfiles/1/edit
  def edit
  end

  # POST /deckfiles
  # POST /deckfiles.json
  def create
    @deckfile = Deckfile.new(deckfile_params)

    respond_to do |format|
      if @deckfile.save
        format.html { redirect_to @deckfile, notice: 'Deckfile was successfully created.' }
        format.json { render :show, status: :created, location: @deckfile }
      else
        format.html { render :new }
        format.json { render json: @deckfile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /deckfiles/1
  # PATCH/PUT /deckfiles/1.json
  def update
    respond_to do |format|
      if @deckfile.update(deckfile_params)
        format.html { redirect_to @deckfile, notice: 'Deckfile was successfully updated.' }
        format.json { render :show, status: :ok, location: @deckfile }
      else
        format.html { render :edit }
        format.json { render json: @deckfile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /deckfiles/1
  # DELETE /deckfiles/1.json
  def destroy
    @deckfile.destroy
    respond_to do |format|
      format.html { redirect_to deckfiles_url, notice: 'Deckfile was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def download
    send_file @deckfile.path
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_deckfile
      @deckfile = Deckfile.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def deckfile_params
      params.require(:deckfile).permit(:disposition, :remove, :path, :dataset_id)
    end
end
