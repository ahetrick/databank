When(/^I agree to deposit agreement$/) do
  check('owner-yes')
  check('private-na')
  check('agree-yes')
  click_on('Submit')
end

When(/^I fill in required dataset metadata$/) do
  fill_in('Title', with: "Test Dataset #{Time.now}")
  select('CC0', from: 'dataset_license')
  fill_in('dataset_creators_attributes_0_family_name', with: "Fallaw")
  fill_in('dataset_creators_attributes_0_given_name', with: "Colleen")
  fill_in('dataset_creators_attributes_0_email', with: "mfall3@mailinator.com")
  choose('primary_contact')
end

When(/^I attach a file$/) do
  testfile_path = "/tmp/test.txt"
  File.open(testfile_path, "w") {|f| f.write("test content") }
  find(:file_field, 'datafile_binary', visible: false).set(testfile_path)
  FileUtils.rm(testfile_path)
end
