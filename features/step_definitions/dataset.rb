When("I deposit a draft dataset") do
  create_draft_dataset
end

Then("I see a draft dataset") do
  expect(page).to have_content("Citation:")
end

private

def create_draft_dataset
  expect(page).to have_selector("#deposit_link", visible: true)
  find("#deposit_link").click
  expect(current_path).to eql("/datasets/pre_deposit")
  click_on("Continue")
  expect(current_path).to eql("/datasets/new")
  find(:css, "#owner-yes").set(true)
  find(:css, "#private-na").set(true)
  find(:css, "#agree-yes").set(true)
  find(:css, "#agree-button").click
  expect(page).to have_selector("input#dataset_title.form-control.dataset")
  fill_in("Dataset Title", with: "Test Dataset Title")
  find("option[value='CC01']").click
  fill_in("dataset_creators_attributes_0_family_name", with: "Smith")
  fill_in("dataset_creators_attributes_0_given_name", with: "Jean")
  fill_in("dataset_creators_attributes_0_email", with: "jean.smith@example.com")
  choose("primary_contact", option: "0")
  find(:css, "#update-save-button").click
end