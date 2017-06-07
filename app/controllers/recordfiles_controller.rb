include ActionView::Helpers::NumberHelper # to pass a display value to a javascript function that adds characters to view
require 'tempfile'
require 'open-uri'
require 'fileutils'
require 'net/http'
require  Rails.root.join('app', 'uploaders', 'binary_uploader.rb')

class RecordfilesController < ApplicationController
  before_action :set_recordfile, only: [:filepath, :preview, :display, :download]

  def filepath
    render json: {filepath: @recordfile.bytestream_path}
  end

  def preview
    @recordfile.record_download(request.remote_ip)
    respond_to do |format|
      format.html {render :preview}
      format.json {render json: {filename: @recordfile.bytestream_name, body: @recordfile.preview, status: :ok}}
    end
  end

  def display
    @recordfile.record_download(request.remote_ip)
    respond_to do |format|
      format.html {
        send_file( @recordfile.bytestream_path,
                   :disposition => 'inline',
                   :type => @recordfile.mime_type,
                   :x_sendfile => true )
      }
      format.json {render json: {filename: @recordfile.bytestream_name, body: @recordfile.preview, status: :ok}}
    end
  end

  def download
    path = @recordfile.bytestream_path
    if path
      send_file path
    end
  end
  

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_recordfile
    @recordfile = Recordfile.find_by_web_id(params[:id])
    raise ActiveRecord::RecordNotFound unless @recordfile
  end
  # Never trust parameters from the scary internet, only allow the white list through.
  def datafile_params
    params.require(:recordfile).permit(:web_id, :dataset_id)
  end

end