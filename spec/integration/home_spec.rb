require 'rails_helper'

describe 'home page', :type => :feature do
  it "introduces the Illinois Data Bank" do
    visit '/'
    assert page.has_content?("The Illinois Data Bank is a public access repository for publishing research data from the University of Illinois at Urbana-Champaign")
  end
end