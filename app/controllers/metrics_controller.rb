class MetricsController < ApplicationController

  def index
  end

  def dataset_downloads
    @dataset_download_tallies = DatasetDownloadTally.all
  end

  def file_downloads
    @file_download_tallies = FileDownloadTally.all
  end

  def datafiles
    datasets = Dataset.where.not(publication_state: Databank::PublicationState::DRAFT).pluck(:id)
    @datafiles = Datafile.where(dataset_id: datasets)


  end

end