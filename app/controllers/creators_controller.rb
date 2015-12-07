class CreatorsController < ApplicationController
  before_action :set_creator, only: [:show, :edit, :update, :destroy]

  # GET /creators
  # GET /creators.json
  def index
    @creators = Creator.all
  end

  # GET /creators/1
  # GET /creators/1.json
  def show
  end

  # GET /creators/new
  def new
    @creator = Creator.new
  end

  # GET /creators/1/edit
  def edit
  end

  # POST /creators
  # POST /creators.json
  def create
    @creator = Creator.new(creator_params)

    respond_to do |format|
      if @creator.save
        format.html { redirect_to @creator, notice: 'Creator was successfully created.' }
        format.json { render :show, status: :created, location: @creator }
      else
        format.html { render :new }
        format.json { render json: @creator.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /creators/1
  # PATCH/PUT /creators/1.json
  def update
    respond_to do |format|
      if @creator.update(creator_params)
        format.html { redirect_to @creator, notice: 'Creator was successfully updated.' }
        format.json { render :show, status: :ok, location: @creator }
      else
        format.html { render :edit }
        format.json { render json: @creator.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /creators/1
  # DELETE /creators/1.json
  def destroy
    @creator.destroy
    respond_to do |format|
      format.html { redirect_to creators_url, notice: 'Creator was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def update_row_order

    @creator = Creator.find(creator_params[:creator_id])
    Rails.logger.warn "creator name: #{@creator.family_name}"
    Rails.logger.warn "row_order before: #{@creator.row_order}"

    row_order_position_integer = Integer(creator_params[:row_order_position])
    Rails.logger.warn "row_order_position_integer: #{row_order_position_integer}"
    Rails.logger.warn "creator_params[:row_order_position] : #{creator_params[:row_order_position]}"

    @creator.update_attribute :row_order_position, row_order_position_integer

    Rails.logger.warn "row_order after: #{@creator.row_order}"
    @creator.save!
    render nothing: true # this is a POST action, updates sent via AJAX, no view rendered

  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_creator
      @creator = Creator.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def creator_params
      params.require(:creator).permit(:dataset_id, :family_name, :given_name, :institution_name, :identifier, :type_of, :row_order_position, :creator_id )
    end
end
