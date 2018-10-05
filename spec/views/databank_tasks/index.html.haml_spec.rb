require 'rails_helper'

RSpec.describe "databank_tasks/index", type: :view do
  before(:each) do
    assign(:databank_tasks, [
      DatabankTask.create!(
        :task_id => 2,
        :status => "MyText"
      ),
      DatabankTask.create!(
        :task_id => 2,
        :status => "MyText"
      )
    ])
  end

  it "renders a list of databank_tasks" do
    render
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
