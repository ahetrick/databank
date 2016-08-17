class ApiDatasetController < ApplicationController

  before_action :authenticate, except: [:index]
  skip_before_action :verify_authenticity_token, only: [:datafile]

  def index
  end

  def datafile

    begin
      df = Datafile.create(dataset_id: @dataset.id, binary: params['binary'])

      unless df && df.binary && df.binary.file && df.binary.file.size > 0
        raise 'Error uploading file. If error persists, please contact the Research Data Service.'
        df.destroy if df
      end

      render json: "successfully uploaded #{df.binary.file.filename}\nsee in dataset at #{IDB_CONFIG[:root_url_text]}/datasets/#{@dataset.key} \n", status: 200
    rescue Exception::StandardError => ex
      Rails.logger.warn ex.message
      render json: "#{ex.message}\n", status: 500
    end

  end

  protected

  def authenticate
    # Rails.logger.warn params
    if params.has_key?(:dataset_key)
      @dataset = Dataset.find_by_key(params[:dataset_key])
      if @dataset  && @dataset.publication_state == Databank::PublicationState::DRAFT
        authenticate_token || render_unauthorized
      else
        render_not_found
      end
    end
  end

  def authenticate_token
    authenticate_or_request_with_http_token do |token, options|
      identified_tokens = Token.where("identifier = ? AND dataset_key = ? AND expires > ?", token, @dataset.key, DateTime.now)
      if identified_tokens.count == 1
        return identified_tokens.first
      elsif identified_token > 1
        identified_tokens.destroy_all
        return nil
      else
        return nil
      end
    end
  end

  def render_unauthorized
    self.headers['WWW-Authenticate'] = 'Token realm="Application"'
    render json: 'Bad credentials', status: 401
  end

  def render_not_found
    render json: 'Dataset Not Found', status: 404
  end

end
