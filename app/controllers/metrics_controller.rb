class MetricsController < ApplicationController

  def index
  end

  def dataset_downloads
    @dataset_download_tallies = DatasetDownloadTally.all
  end

  def file_downloads
    @file_download_tallies = FileDownloadTally.all
  end

  def datafiles_simple_list
    datasets = Dataset.where.not(publication_state: Databank::PublicationState::DRAFT).pluck(:id)
    @datafiles = Datafile.where(dataset_id: datasets)
  end

  def datasets_csv

    t = Tempfile.new("datasets_csv")

    datasets = Dataset.where.not(publication_state: Databank::PublicationState::DRAFT)

    csv_string = "doi,pub_date,num_files,num_bytes,total_downloads,num_relationships"

    datasets.each_with_index do |dataset, i|

      line = "\n#{dataset.identifier},#{dataset.release_date.iso8601},#{dataset.datafiles.count},#{dataset.total_filesize},#{dataset.total_downloads},#{dataset.num_external_relationships}"
      csv_string = csv_string + line

    end

    t.write(csv_string)

    send_file t.path, :type => 'text/csv',
              :disposition => 'attachment',
              :filename => "datasets.csv"

    t.close

  end

  def datafiles_csv

    datasets = Dataset.where.not(publication_state: Databank::PublicationState::DRAFT).pluck(:id)
    @datafiles = Datafile.where(dataset_id: datasets)

  end

  def related_materials_csv

  end



end