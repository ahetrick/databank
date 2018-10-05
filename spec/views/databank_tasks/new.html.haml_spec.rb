require 'rails_helper'

RSpec.describe "databank_tasks/new", type: :view do
  before(:each) do
    assign(:databank_task, DatabankTask.new(
      :task_id => 1,
      :status => "MyText"
    ))
  end

  it "renders new databank_task form" do
    render

    assert_select "form[action=?][method=?]", databank_tasks_path, "post" do

      assert_select "input#databank_task_task_id[name=?]", "databank_task[task_id]"

      assert_select "textarea#databank_task_status[name=?]", "databank_task[status]"
    end
  end
end
