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
    @datafiles = Datafile.all
  end

end