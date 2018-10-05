require 'rails_helper'

RSpec.describe "databank_tasks/edit", type: :view do
  before(:each) do
    @databank_task = assign(:databank_task, DatabankTask.create!(
      :task_id => 1,
      :status => "MyText"
    ))
  end

  it "renders the edit databank_task form" do
    render

    assert_select "form[action=?][method=?]", databank_task_path(@databank_task), "post" do

      assert_select "input#databank_task_task_id[name=?]", "databank_task[task_id]"

      assert_select "textarea#databank_task_status[name=?]", "databank_task[status]"
    end
  end
end
