=begin
Given(/^Dataset exists with files named:$/) do |table|

  @dataset = FactoryGirl.create(:dataset, publication_state: "released")
  @dataset.identifier =  "10.5027/FK2#{@dataset.key}_V1"
  @dataset.save
  creator = FactoryGirl.create(:creator, dataset_id: @dataset.id)

  table.headers.each do |header|
    testfile_path = "/tmp/#{header}"
    File.open(testfile_path, "w") {|f| f.write("test content") }
    datafile = Datafile.create(dataset_id: @dataset.id)
    datafile.binary = Pathname.new(testfile_path).open
    datafile.save
  end
end

When(/^I check the box: (.*)$/) do |checkbox_identifier|
  check(checkbox_identifier)
end

Then(/^I uncheck the box: (.*)$/) do |checkbox_identifier|
  uncheck(checkbox_identifier)
end
=end
