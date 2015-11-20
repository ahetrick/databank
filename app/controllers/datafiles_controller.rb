include ActionView::Helpers::NumberHelper # to pass a display value to a javascript function that adds characters to view

class DatafilesController < ApplicationController
  before_action :set_datafile, only: [:show, :edit, :update, :destroy, :download]

  # GET /datafiles
  # GET /datafiles.json
  def index
    @datafiles = Datafile.all
  end

  # GET /datafiles/1
  # GET /datafiles/1.json
  def show
  end

  # GET /datafiles/new
  def new
    @datafile = Datafile.new
  end

  # GET /datafiles/1/edit
  def edit
  end

  # POST /datafiles
  # POST /datafiles.json
  def create

    @datafile = Datafile.create(datafile_params)
    render(json: to_fileupload, content_type: request.format, :layout => false )

    # respond_to do |format|
    #   if @datafile.save
    #     format.html { redirect_to @datafile, notice: 'Datafile was successfully created.' }
    #     format.json { render :show, status: :created, location: @datafile }
    #   else
    #     format.html { render :new }
    #     format.json { render json: @datafile.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  def create_from_box

    # Rails.logger.warn params[:url]


    # Rails.logger.warn params.to_yaml

    # File.open("#{Rails.root}/public/uploads/test.txt", 'w+') { |file| file.write("your text") }

    @dataset = Dataset.find_by_key(params[:dataset_key])

    #@job = Delayed::Job.enqueue CreateDatafileFromRemoteJob.new(progress_max: 100 )

    # @datafile = Datafile.create(:remote_binary_url => params[:url], :dataset_id => dataset.id)

    # CreateDatafileFromRemoteJob.perform_later(params[:url], dataset.id)

    @filename = params[:name]
    @filesize = params[:size]
    @filesize_display = "#{number_to_human_size(@filesize)}"

    @datafile = Datafile.create(:dataset_id => @dataset.id)

    @job = Delayed::Job.enqueue CreateDatafileFromRemoteJob.new(@dataset.id, @datafile, params[:url], @filename, @filesize)

    # @job = Delayed::Job.enqueue CreateDatafileFromRemoteJob.new(dataset.id, params[:url], 100)

    # CreateDatafileFromRemoteJob.perform_later(params[:dataset_key], params[:url], 100 )

    # render(json: to_fileupload, content_type: request.format, :layout => false )
  end

  # PATCH/PUT /datafiles/1
  # PATCH/PUT /datafiles/1.json
  def update
    respond_to do |format|
      if @datafile.update(datafile_params)
        format.html { redirect_to @datafile, notice: 'Datafile was successfully updated.' }
        format.json { render :show, status: :ok, location: @datafile }
      else
        format.html { render :edit }
        format.json { render json: @datafile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /datafiles/1
  # DELETE /datafiles/1.json
  def destroy
    @dataset = Dataset.find(@datafile.dataset_id)

    @datafile.destroy

    redirect_to edit_dataset_path(@dataset.key)
    # respond_to do |format|
    #   format.html { redirect_to datafiles_url, notice: 'Datafile was successfully destroyed.' }
    #   format.json { head :no_content }
    # end
  end

  def download
    path = @datafile.binary.path
    send_file path, :x_sendfile=>true
  end

  def to_fileupload
    {
        files:
            [
                {
                    web_id: @datafile.web_id,
                    url: "dafafiles/#{@datafile.web_id}",
                    name: "#{@datafile.binary.file.filename}",
                    size: "#{number_to_human_size(@datafile.binary.size)}"
                }
            ]
    }

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_datafile
      @datafile = Datafile.find_by_web_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @datafile
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def datafile_params
      params.require(:datafile).permit(:description, :binary, :web_id, :dataset_id)
    end
end
