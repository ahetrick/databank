class DatasetsController < ApplicationController
  before_action :set_dataset, only: [:show, :edit, :update, :destroy]

  # GET /datasets
  # GET /datasets.json
  def index
    @datasets = Dataset.all
  end

  # GET /datasets/1
  # GET /datasets/1.json
  def show
  end

  # GET /datasets/new
  def new
    if params.keys.include?("input_title")
      create_or_update_if_valid_input(params)
    end
  end

  def create_or_update_if_valid_input(input)

    if input["input_title"].empty?
      # should only get here if bootstrap form validation failed
      raise 'dataset title must not be empty'
    end

    if input["input_creator_name_list"].empty?
      # should only get here if bootstrap form validation failed
      raise 'dataset creator name list must not be empty'
    end

    if params.keys.include?(:id)
      @dataset = Dataset.find(:id)
      @dataset.title = input["input_title"]
      @dataset.identifier = input["input_identifier"]
      @dataset.publisher = "University of Illinois at Urbana-Champaign"
      @dataset.publication_year = input["input_publication_year"]
      @dataset.description = input["input_description"]
      @dataset.rights = input["input_rights"]
    else
      @dataset = Dataset.new :title => input["input_title"],
                             :identifier => input["input_identifier"],
                             :publisher => "University of Illinois at Urbana-Champaign",
                             :publication_year => input["input_publication_year"],
                             :description => input["input_description"],
                             :rights => input["input_rights"]
    end
    @dataset.save!
    creator_array = input["input_creator_name_list"].split(";")
    creator_id_list = ""
    creator_array.each_with_index do |creator_name, index|
      creator = Creator.new :creator_name => creator_name, :dataset_id => @dataset.id
      creator.save!
      if index > 0
        creator_id_list << ","
      end
      creator_id_list << creator.id.to_s
    end
    @dataset.creator_ordered_ids = creator_id_list

    params[:action] == 'new' ? action_word = 'created' : action_word = 'updated'

    respond_to do |format|
      if @dataset.save
        format.html { redirect_to @dataset, notice: "Dataset was successfully #{action_word}." }
        format.json { render :show, status: :created, location: @dataset }
      else
        format.html { render :new }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end
    end

  end

  # GET /datasets/1/edit
  def edit
    if params.keys.include?("input_title")
      create_or_update_if_valid_input(params)
    end
  end

  # POST /datasets
  # POST /datasets.json
  def create
    @dataset = Dataset.new(dataset_params)

    respond_to do |format|
      if @dataset.save
        format.html { redirect_to @dataset, notice: 'Dataset was successfully created.' }
        format.json { render :show, status: :created, location: @dataset }
      else
        format.html { render :new }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /datasets/1
  # PATCH/PUT /datasets/1.json
  def update

    respond_to do |format|
      if @dataset.update(dataset_params)
        format.html { redirect_to @dataset, notice: 'Dataset was successfully updated.' }
        format.json { render :show, status: :ok, location: @dataset }
      else
        format.html { render :edit }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end
    end

  end

  # DELETE /datasets/1
  # DELETE /datasets/1.json
  def destroy
    @dataset.destroy
    respond_to do |format|
      format.html { redirect_to datasets_url, notice: 'Dataset was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_dataset
    @dataset = Dataset.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def dataset_params
    params.require(:dataset).permit(:input_title, :input_identifier, :input_publication_year, :input_rights, :input_description, :input_creator_name_list)
  end

end
