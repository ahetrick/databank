namespace :recordfile do

  desc 'retrofit datasets with recordfiles'
  task :add_legacy_recordfiles => :environment do
    datasets = Dataset.all
    datasets.each do |dataset|
      unless dataset.recordfile

        begin

          # create or confirm dataset_staging directory for dataset
          dataset_dirname = "DOI-#{(dataset.identifier).parameterize}"
          staging_dir = "#{IDB_CONFIG[:staging_root]}/#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}"

          FileUtils.mkdir_p "#{staging_dir}/system"
          FileUtils.chmod "u=wrx,go=rx", File.dirname(staging_dir)

          file_time = Time.now.strftime('%Y-%m-%d_%H-%M')

          # write recordfile

          recordfilename = "dataset_info_#{file_time}.txt"
          record_filepath = "#{staging_dir}/system/#{recordfilename}"

          File.open(record_filepath, "w") do |recordfile|
            recordfile.puts(dataset.recordtext)
          end

          recordfile = Recordfile.create(dataset_id: dataset.id)
          recordfile.binary = Pathname.new(record_filepath).open
          recordfile.binary_name = recordfile.binary.file.filename
          recordfile.binary_size = recordfile.binary.size
          recordfile.save

          # make symlink, because setting as binary removes the file and puts it in uploads

          FileUtils.ln(recordfile.bytestream_path, record_filepath)
          FileUtils.chmod "u=wrx,go=rx", recordfile.bytestream_path

          medusa_ingest = MedusaIngest.new
          staging_path = "#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}/system/#{recordfilename}"
          medusa_ingest.staging_path = staging_path
          medusa_ingest.idb_class = 'recordfile'
          medusa_ingest.idb_identifier = recordfile.web_id
          medusa_ingest.send_medusa_ingest_message(staging_path)
          medusa_ingest.save

        rescue Exception => ex

          puts ex.message
          raise ex
          
        end

      end
    end
  end

end