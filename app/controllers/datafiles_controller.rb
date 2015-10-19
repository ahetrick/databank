class DatafilesController < ApplicationController
  
  RESULTS_PER_PAGE = 10

  before_action :set_dataset, only: [:new, :create, :edit, :show]
  before_action :set_datafile, only: [:edit, :show, :destroy, :master_bytestream]

  ##
  # Redirects to an datafile's master bytestream in the repository.
  #
  # Responds to GET /datafiles/:web_id/master
  #
  def master_bytestream
    redirect_to bytestream_url(@datafile.master_bytestream)
  end

  def index
    @start = params[:start] ? params[:start].to_i : 0
    @limit = RESULTS_PER_PAGE
    @datafiles = Repository::Datafile.where("-#{Solr::Fields::DATAFILE}:[* TO *]").
        where(params[:q])
    if params[:fq].respond_to?(:each)
      params[:fq].each { |fq| @datafiles = @datafiles.facet(fq) }
    else
      @datafiles = @datafiles.facet(params[:fq])
    end

    if params[:dataset_key]
      @dataset = Dataset.find_by_key(params[:dataset_key])
      raise ActiveRecord::RecordNotFound, 'Dataset not found' unless @dataset
      @datafiles = @dataset.datafiles
    end

    # if there is no user-entered query, sort by title. Otherwise, use the
    # default sort, which is by relevance
    @datafiles = @datafiles.order(Solr::Fields::SINGLE_TITLE) if params[:q].blank?
    @datafiles = @datafiles.start(@start).limit(@limit)
    @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
    @num_results_shown = [@limit, @datafiles.total_length].min

    respond_to do |format|
      format.html do
        # if there are no results, get some suggestions
        if @datafiles.total_length < 1 and params[:q].present?
          @suggestions = Solr::Solr.new.suggestions(params[:q])
        end
      end

    end
  end


  def create

    if params[:datafile][:file_upload]

      @datafile = Repository::Datafile.new(
          repo_dataset: @dataset.repo_dataset,
          parent_url: (@dataset.repo_dataset).id,
          published: true,
          description: params[:datafile][:description])

      @datafile.save!

      upload_io = params[:datafile][:file_upload].tempfile

      bytestream = Repository::Bytestream.new(
          parent_url: @datafile.id,
          type: Repository::Bytestream::Type::MASTER,
          datafile: @datafile,
          upload_filename:  params[:datafile][:file_upload].original_filename,
          upload_io: upload_io)

      bytestream.save!

      redirect_to dataset_path(@dataset.key)

    else
      raise "no file detected"
    end


  end

  ##
  # Responds to POST /search. Translates the input from the advanced search
  # form into a query string compatible with DatafilesController.index, and
  # 302-redirects to it.
  #
  def search
    where_clauses = []

    # fields
    if params[:fields].any?
      params[:fields].each_with_index do |field, index|
        if params[:terms].length > index and !params[:terms][index].blank?
          where_clauses << "#{field}:#{params[:terms][index]}"
        end
      end
    end

    # datasets
    keys = []
    if params[:keys].any?
      keys = params[:keys].select{ |k| !k.blank? }
    end
    if keys.any? and keys.length < Repository::Dataset.all.length
      where_clauses << "#{Solr::Fields::DATASET_KEY}:+(#{keys.join(' ')})"
    end

    redirect_to repository_datafiles_path(q: where_clauses.join(' AND '))
  end

  def show
    begin
      @datafile = Repository::Datafile.find_by_web_id(params[:web_id])
    rescue ActiveMedusa::RepositoryError => e
      render text: '410 Gone', status: 410 if e.res.code == 410
      @skip_after_actions = true
      return
    end
    raise ActiveRecord::RecordNotFound, 'Datafile not found' unless @datafile

    uri = repository_datafile_url(@datafile)
    respond_to do |format|
      format.html do
        @pages = @datafile.parent_datafile.kind_of?(Repository::Datafile) ?
            @datafile.parent_datafile.datafiles : @datafile.datafiles
      end

    end
  end

  private

  def set_dataset
    @dataset = Dataset.find_by_key(params[:dataset_key])
    raise ActiveRecord::RecordNotFound, 'Dataset not found' unless @dataset
  end

  def set_datafile
    @datafile = Repository::Datafile.find_by_web_id(params[:web_id])
    raise ActiveRecord::RecordNotFound, 'Datafile not found' unless @datafile
  end

  def dataset_params
    params.require(:datafile).permit(:description, :dataset_id, :file_upload)
  end
end