require "application_system_test_case"

class VisualizationsTest < ApplicationSystemTestCase
  setup do
    @visualization = visualizations(:one)
  end

  test "visiting the index" do
    visit visualizations_url
    assert_selector "h1", text: "Visualizations"
  end

  test "creating a Visualization" do
    visit visualizations_url
    click_on "New Visualization"

    fill_in "Chart class", with: @visualization.chart_class
    fill_in "Data", with: @visualization.data
    fill_in "Datafile web", with: @visualization.datafile_web_id
    fill_in "Dataset key", with: @visualization.dataset_key
    fill_in "Options", with: @visualization.options
    click_on "Create Visualization"

    assert_text "Visualization was successfully created"
    click_on "Back"
  end

  test "updating a Visualization" do
    visit visualizations_url
    click_on "Edit", match: :first

    fill_in "Chart class", with: @visualization.chart_class
    fill_in "Data", with: @visualization.data
    fill_in "Datafile web", with: @visualization.datafile_web_id
    fill_in "Dataset key", with: @visualization.dataset_key
    fill_in "Options", with: @visualization.options
    click_on "Update Visualization"

    assert_text "Visualization was successfully updated"
    click_on "Back"
  end

  test "destroying a Visualization" do
    visit visualizations_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Visualization was successfully destroyed"
  end
end
