require 'rails_helper'

RSpec.describe "ingest_responses/edit", type: :view do
  before(:each) do
    @ingest_response = assign(:ingest_response, IngestResponse.create!(
      :as_text => "MyText",
      :status => "MyString",
      :staging_key => "MyString",
      :medusa_key => "MyString",
      :uuid => "MyString"
    ))
  end

  it "renders the edit ingest_response form" do
    render

    assert_select "form[action=?][method=?]", ingest_response_path(@ingest_response), "post" do

      assert_select "textarea#ingest_response_as_text[name=?]", "ingest_response[as_text]"

      assert_select "input#ingest_response_status[name=?]", "ingest_response[status]"

      assert_select "input#ingest_response_staging_key[name=?]", "ingest_response[staging_key]"

      assert_select "input#ingest_response_medusa_key[name=?]", "ingest_response[medusa_key]"

      assert_select "input#ingest_response_uuid[name=?]", "ingest_response[uuid]"
    end
  end
end
