require 'rails_helper'

RSpec.describe "ingest_responses/index", type: :view do
  before(:each) do
    assign(:ingest_responses, [
      IngestResponse.create!(
        :as_text => "MyText",
        :status => "Status",
        :staging_key => "Staging Key",
        :medusa_key => "Medusa Key",
        :uuid => "Uuid"
      ),
      IngestResponse.create!(
        :as_text => "MyText",
        :status => "Status",
        :staging_key => "Staging Key",
        :medusa_key => "Medusa Key",
        :uuid => "Uuid"
      )
    ])
  end

  it "renders a list of ingest_responses" do
    render
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "Status".to_s, :count => 2
    assert_select "tr>td", :text => "Staging Key".to_s, :count => 2
    assert_select "tr>td", :text => "Medusa Key".to_s, :count => 2
    assert_select "tr>td", :text => "Uuid".to_s, :count => 2
  end
end
