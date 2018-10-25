require 'rails_helper'
require 'json'

RSpec.describe Dataset, type: :model do

  # create simulation of what would be in Medusa system directory, except deposit agreement
  def write_medusa_system_files(dataset)

    # set event time
    file_time = Time.now.strftime('%Y-%m-%d_%H-%M')

    # create or confirm mock medusa system directory exists for this dataset
    dir = "#{IDB_CONFIG['medusa']['medusa_path_root']}/DOI-#{(dataset.identifier).parameterize}/system"
    FileUtils::mkdir_p dir unless Dir.exists?(dir)

    # write description file
    description_xml = Dataset.to_datacite_xml(dataset)
    File.open("#{dir}/description.#{file_time}.xml", "w") do |description_file|
      description_file.puts(description_xml)
    end

    # write serialization file
    serialization_json = (dataset.recovery_serialization).to_json
    File.open("#{dir}/serialization.#{file_time}.json", "w") do |serialization_file|
      serialization_file.puts(serialization_json)
    end

    changelog_json = (dataset.full_changelog).to_json
    File.open("#{dir}/changelog.#{file_time}.json", "w") do |changelog_file|
      changelog_file.write(changelog_json)
    end
  end



  #pending "add some examples to (or delete) #{__FILE__}"

  before(:each) do
    @dataset = Dataset.create(title: "Test Dataset",
                             publisher: "University of Illinois at Urbana-Champaign",
                             license: "CC01",
                             depositor_name: "Colleen Fallaw",
                             depositor_email: "mfall3@mailinator.com",
                             corresponding_creator_name: "Colleen Fallaw",
                             corresponding_creator_email: "mfall3@mailinator.com",
                             curator_hold: false,
                             publication_state: "released",
                             embargo: "none",
                             is_test: false,
                             is_import: false,
                             have_permission: "yes",
                             removed_private: "na",
                             agree: "yes",
                             hold_state: "none",
                             dataset_version: "1",
                             suppress_changelog: false, creators_attributes: [{family_name: "Last",
                                                                               given_name: "First",
                                                                               type_of: 0,
                                                                               email: "creator@mailinator.com",
                                                                               is_contact: true,
                                                                               row_position: 1,
                                                                               identifier_scheme: "ORCID"}])
    @dataset.identifier = "10.5027/FK2#{@dataset.key}_V1"
    @dataset.save
    @recovery_hash = JSON.parse(@dataset.recovery_serialization.to_json, {quirks_mode: true})
    @independent_identifier = @dataset.identifier
    write_medusa_system_files(@dataset)
    @dataset.title = "Changed Title"
    creator = @dataset.creators.first
    creator.family_name = "Smith"
    creator.save
    funder = @dataset.funders.build(dataset_id: @dataset.id, name: "DOE", identifier: "10.13039/100000015", identifier_scheme: "DOI", grant: "Test123")
    funder.save
    @dataset.save
    write_medusa_system_files(@dataset)

  end

  describe '#plain_text_citation' do

    it "returns a string in the expected format" do
      expect(@dataset.plain_text_citation.strip).to eq("Smith, First (#{@dataset.publication_year}): Changed Title. University of Illinois at Urbana-Champaign. https://doi.org/#{@dataset.identifier}".strip)
    end

  end

  describe ".get_serialzation_json_from_medusa" do

    it "returns content string of the only existing serialization file" do
      file_time = Time.now.strftime('%Y-%m-%d_%H-%M')
      dir = "#{IDB_CONFIG['medusa']['medusa_path_root']}/DOI-#{(@dataset.identifier.tr('.', '-').tr('/', '-')).downcase}/system"
      FileUtils::mkdir_p dir

      serialization_test_instance = (@dataset.recovery_serialization).to_json
      File.open("#{dir}/serialization.#{file_time}.json", "w") do |serialization_file|
        serialization_file.puts(serialization_test_instance)
      end
      FileUtils.chmod 0755, "#{dir}/serialization.#{file_time}.json"
      serialization_from_medusa = Dataset.get_serialzation_json_from_medusa(@dataset.identifier)
      expect(serialization_from_medusa.strip).to eq(serialization_test_instance)
    end

    #TODO: set up mutlipe serialzation scenario
    it "returns content string of most recent serialization file" #do
    #   serialization = Dataset.get_serialzation_json_from_medusa("10.5072/fk2idblocal-6229208_v1")
    #   expect(serialization).to eq(%Q[{"test":"ok", "time":"2016-07-27_15-46"}])
    # end

  end

  describe '.serializations_from_medusa' do
    it "returns an array" do
      serializations = Dataset.serializations_from_medusa
      expect(serializations).to be_kind_of(Array)
    end
  end

  describe '#recovery_serialization' do

    it "returns a Hash" do
      generated_serialization = @dataset.recovery_serialization
      #puts generated_serialization
      #puts generated_serialization.class
      expect(generated_serialization).to be_kind_of(Hash)
    end

    it "can be tranformed to json-compabible hash " do
      # puts @recovery_hash.class
      expect(@recovery_hash).to be_kind_of(Hash)
    end

    it "has creators array with at least one element" do
      expect(@recovery_hash['idb_dataset']['creators'].length).to be > 0
    end

  end


  describe '.get_serialzation_json_from_medusa' do

    it "returns same serialization as is produced from object" do

      serialization = Dataset.get_serialzation_json_from_medusa(@independent_identifier)
      expect(serialization.strip).to eq(@dataset.recovery_serialization.to_json.strip)
    end

  end

  # describe '.restore_db_from_serialization' do
  #
  #   it "raises an error if the identifier already exists in database" do
  #     serialzation_from_medusa = Dataset.get_serialzation_json_from_medusa(@independent_identifier)
  #     expect{Dataset.restore_db_from_serialization(serialzation_from_medusa, RestorationEvent.create())}.to raise_error("record already exists in database")
  #   end
  #
  #   it "adds a duplicate dataset to the database" do
  #
  #     funder = @dataset.funders.build(dataset_id: @dataset.id, name: "DOE", identifier: "10.13039/100000015", identifier_scheme: "DOI", grant: "RFA-Unicorns")
  #     funder.save
  #     #puts funder.to_yaml
  #     @dataset.save
  #
  #     file_time = Time.now.strftime('%Y-%m-%d_%H-%M')
  #     serialization_json = (@dataset.recovery_serialization).to_json
  #     dir = "#{IDB_CONFIG['medusa']['medusa_path_root']}/DOI-#{(@dataset.identifier.tr('.', '-').tr('/', '-')).downcase}/system"
  #     FileUtils::mkdir_p dir
  #     writepath = "#{dir}/serialization.#{file_time}.json"
  #     File.open(writepath, "w") do |serialization_file|
  #       serialization_file.puts(serialization_json)
  #     end
  #     FileUtils.chmod 0755, writepath
  #
  #     serialzation_from_medusa = Dataset.get_serialzation_json_from_medusa(@independent_identifier)
  #
  #     puts @dataset.funders.count
  #
  #     dataset_copy = @dataset.dup
  #
  #     @dataset.destroy
  #     restored_dataset = nil
  #     #puts Dataset.count
  #     expect {restored_dataset = Dataset.restore_db_from_serialization(serialzation_from_medusa, RestorationEvent.create())}.to change{Dataset.count}.by(1)
  #     #puts Dataset.count
  #     #puts restored_dataset.to_yaml
  #
  #     expect(dataset_copy.title).to eq(restored_dataset.title)
  #     expect(dataset_copy.publisher).to eq(restored_dataset.publisher)
  #     expect(dataset_copy.license).to eq(restored_dataset.license)
  #     expect(dataset_copy.depositor_name).to eq(restored_dataset.depositor_name)
  #     expect(dataset_copy.depositor_email).to eq(restored_dataset.depositor_email)
  #     expect(dataset_copy.corresponding_creator_name).to eq(restored_dataset.corresponding_creator_name)
  #     expect(dataset_copy.corresponding_creator_email).to eq(restored_dataset.corresponding_creator_email)
  #     expect(dataset_copy.curator_hold).to eq(restored_dataset.curator_hold)
  #     expect(dataset_copy.publication_state).to eq(restored_dataset.publication_state)
  #     expect(dataset_copy.embargo).to eq(restored_dataset.embargo)
  #     expect(dataset_copy.is_test).to eq(restored_dataset.is_test)
  #     expect(dataset_copy.is_import).to eq(restored_dataset.is_import)
  #     expect(dataset_copy.have_permission).to eq(restored_dataset.have_permission)
  #     expect(dataset_copy.removed_private).to eq(restored_dataset.removed_private)
  #     expect(dataset_copy.agree).to eq(restored_dataset.agree)
  #     expect(dataset_copy.hold_state).to eq(restored_dataset.hold_state)
  #     expect(dataset_copy.dataset_version).to eq(restored_dataset.dataset_version)
  #     expect(dataset_copy.suppress_changelog).to eq(restored_dataset.suppress_changelog)
  #     expect(dataset_copy.keywords).to eq(restored_dataset.keywords)
  #     expect(dataset_copy.key).to eq(restored_dataset.key)
  #     expect(dataset_copy.identifier).to eq(restored_dataset.identifier)
  #     expect(dataset_copy.medusa_dataset_dir).to eq(restored_dataset.medusa_dataset_dir)
  #     expect(dataset_copy.description).to eq(restored_dataset.description)
  #     expect(dataset_copy.medusa_dataset_dir).to eq(restored_dataset.medusa_dataset_dir)
  #     expect(restored_dataset.funders.count).to eq(1)
  #
  #   end
  #
  # end

  describe '.get_changelog_from_medusa' do
    it 'returns changelog' do
      expect(Dataset.get_changelog_from_medusa(@independent_identifier).strip).to eq((@dataset.full_changelog).to_json.strip)
    end
  end

end
