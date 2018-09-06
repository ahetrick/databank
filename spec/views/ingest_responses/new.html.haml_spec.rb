require 'rails_helper'

RSpec.describe "ingest_responses/new", type: :view do
  before(:each) do
    assign(:ingest_response, IngestResponse.new(
      :as_text => "MyText",
      :status => "MyString",
      :staging_key => "MyString",
      :medusa_key => "MyString",
      :uuid => "MyString"
    ))
  end

  it "renders new ingest_response form" do
    render

    assert_select "form[action=?][method=?]", ingest_responses_path, "post" do

      assert_select "textarea#ingest_response_as_text[name=?]", "ingest_response[as_text]"

      assert_select "input#ingest_response_status[name=?]", "ingest_response[status]"

      assert_select "input#ingest_response_staging_key[name=?]", "ingest_response[staging_key]"

      assert_select "input#ingest_response_medusa_key[name=?]", "ingest_response[medusa_key]"

      assert_select "input#ingest_response_uuid[name=?]", "ingest_response[uuid]"
    end
  end
end
