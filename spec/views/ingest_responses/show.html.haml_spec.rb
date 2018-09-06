require 'rails_helper'

RSpec.describe "ingest_responses/show", type: :view do
  before(:each) do
    @ingest_response = assign(:ingest_response, IngestResponse.create!(
      :as_text => "MyText",
      :status => "Status",
      :staging_key => "Staging Key",
      :medusa_key => "Medusa Key",
      :uuid => "Uuid"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/Status/)
    expect(rendered).to match(/Staging Key/)
    expect(rendered).to match(/Medusa Key/)
    expect(rendered).to match(/Uuid/)
  end
end
