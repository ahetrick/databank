require 'rails_helper'

RSpec.describe "databank_tasks/show", type: :view do
  before(:each) do
    @databank_task = assign(:databank_task, DatabankTask.create!(
      :task_id => 2,
      :status => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/2/)
    expect(rendered).to match(/MyText/)
  end
end
