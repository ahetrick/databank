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

    datasets.each do |dataset|

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

    doi_filename_mimetype = JSON.parse MedusaInfo.doi_filename_mimetype

    return nil unless doi_filename_mimetype

    t = Tempfile.new("datafiles_csv")

    datasets = Dataset.where.not(publication_state: Databank::PublicationState::DRAFT)

    csv_string = "doi,pub_date,filename,file_format,num_bytes,total_downloads"

    datasets = Dataset.where.not(publication_state: Databank::PublicationState::DRAFT)

    datasets.each do |dataset|
      dataset.datafiles.each do |datafile|
        line = "\n#{dataset.identifier},#{dataset.release_date.iso8601},#{datafile.bytestream_name},#{doi_filename_mimetype[dataset.identifier]},#{datafile.bytestream_size},#{datafile.total_downloads}"
        csv_string = csv_string + line
      end
    end

    t.write(csv_string)

    send_file t.path, :type => 'text/csv',
              :disposition => 'attachment',
              :filename => "datafiles.csv"

    t.close

  end

  def related_materials_csv

    t = Tempfile.new("related_materials_csv")

    datasets = Dataset.where.not(publication_state: Databank::PublicationState::DRAFT)

    csv_string = "doi,material_id,material_id_type,material_type"

    datasets = Dataset.where.not(publication_state: Databank::PublicationState::DRAFT)

    datasets.each do |dataset|
      dataset.related_materials.each do |material|
        line = "\n#{dataset.identifier},#{material.uri},#{material.uri_type},#{material.selected_type}"
        csv_string = csv_string + line
      end
    end

    t.write(csv_string)

    send_file t.path, :type => 'text/csv',
              :disposition => 'attachment',
              :filename => "related_materials.csv"

    t.close

  end



end