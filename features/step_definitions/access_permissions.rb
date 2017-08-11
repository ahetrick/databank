Then(/^I see shaded background on curator elements/) do
  expect(page).to have_css('.curator-only')
end