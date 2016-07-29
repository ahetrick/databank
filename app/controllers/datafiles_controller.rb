include ActionView::Helpers::NumberHelper # to pass a display value to a javascript function that adds characters to view
require 'tempfile'
require 'open-uri'
require 'fileutils'
require 'net/http'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class DatafilesController < ApplicationController

  before_action :set_datafile, only: [:show, :edit, :update, :destroy, :download, :record_download]
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
    Rails.logger.warn datafile_params
    @datafile = Datafile.create(datafile_params)
    render(json: to_fileupload, content_type: request.format, :layout => false)
  end

  def create_from_url

    # Rails.logger.warn "inside create from url"
    # Rails.logger.warn params.to_yaml

    @dataset ||= Dataset.find_by_key(params[:dataset_key])

    @filename ||= "not_specified"
    @filesize ||= 0

    if params.has_key?(:name)
      @filename = params[:name]
    end
    if params.has_key?(:size)
      @filesize = params[:size]
    end

    @filesize_display = "#{number_to_human_size(@filesize)}"

    @datafile ||= Datafile.create(dataset_id: @dataset.id)

    @job = Delayed::Job.enqueue CreateDatafileFromRemoteJob.new(@dataset.id, @datafile, params[:url], @filename, @filesize)

    @datafile.job_id = @job.id
    @datafile.box_filename = @filename
    @datafile.box_filesize_display = @filesize_display
    @datafile.save
  end

  def create_from_deckfile

    @datafile= Datafile.new
    @dataset = Dataset.find_by_key(params[:dataset_key])
    @deckfile = Deckfile.find(params[:deckfile_id])
    if @dataset && @deckfile
      @datafile.dataset_id = @dataset.id

      if File.file?(@deckfile.path)
        @datafile.binary = Pathname.new(@deckfile.path).open
      else
        raise "file not detected"
      end
      @datafile.save!
    end
    @deckfile.destroy!

    render(json: to_fileupload, content_type: request.format, :layout => false)


  end

  def remote_content_length

    response = nil

    @remote_url = params["remote_url"]

    uri = URI.parse(@remote_url)

    Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https')) { |http|
        response = http.request_head(uri.path)
    }

    # Rails.logger.warn "content length: #{response['content-length']}"

    if response['content-length']

      remote_content_length = Integer(response['content-length']) rescue nil

      if remote_content_length && remote_content_length > 0

         render(json: {"status":"ok", "remote_content_length":remote_content_length }, content_type: request.format, layout: false)

      else

        render(json: {"status":"error", "error":"error getting remote content length"}, content_type: request.format, layout: false)

      end

    else
      render(json: {"status":"error", "error":"error getting content length from url"}, content_type: request.format, layout: false)
    end
  end

  def create_from_url_unknown_size

    @datafile = Datafile.new
    @dataset = Dataset.find_by_key(params[:dataset_key])
    if @dataset
      @datafile.dataset_id = @dataset.id
      @remote_url = params["remote_url"]
      @filename = params["remote_filename"]

      dir_name = "#{Rails.root}/public/uploads/#{@dataset.id}"

      FileUtils.mkdir_p(dir_name) unless File.directory?(dir_name)

      filepath = "#{dir_name}/#{@filename}"

      File.open(filepath, 'wb+') do |outfile|
        uri = URI.parse(@remote_url)

        Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https')) { |http|
          http.request_get(uri.path) { |res|
            res.read_body { |seg|

              if File.size(outfile) < 1000000000000
               outfile << seg
              else
                @datafile.destroy
                render(json: {files:[{datafileId: 0,webId: "error",url: "error",name: "error: filesize exceeds 1TB",size: "0"}]}, content_type: request.format, :layout => false)
              end
            }
          }
        }

      end

      if File.file?(filepath)
        @datafile.binary = Rails.root.join("public/uploads/#{@dataset.id}/#{@filename}").open
      else
        raise "error in ingesting file from url"
      end
      @datafile.save!
    else
      raise "dataset not found for ingest from url"
    end

    render(json: to_fileupload, content_type: request.format, :layout => false)


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
  end

  def download
    @datafile.record_download(request.remote_ip)
    path = @datafile.bytestream_path
    send_file path
  end

  def to_fileupload
    {
        files:
            [
                {
                    datafileId: @datafile.id,
                    webId: @datafile.web_id,
                    url: "datafiles/#{@datafile.web_id}",
                    name: "#{@datafile.binary.file.filename}",
                    size: "#{number_to_human_size(@datafile.binary.size)}"
                }
            ]
    }

  end

  def record_download
    @datafile.record_download(request.remote_ip)
    render json: {status: :ok}
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
