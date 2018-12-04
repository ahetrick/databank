class DatabankTasksController < ApplicationController

  # GET /databank_tasks
  # GET /databank_tasks.json
  def index
    @databank_tasks = [] #DatabankTask.get_all_remote_tasks
  end

  # GET /databank_tasks/1
  # GET /databank_tasks/1.json
  def show
    @databank_task = DatabankTask.get_remote_task(params[:id])
  end

  def pending
    @databank_tasks = DatabankTask.get_pending_tasks
  end

  def update_status
    if DatabankTask.set_remote_task_status(params[:id], params[:status])
      render json: {status: :ok}
    else
      render json: {status: :unprocessable_entity}
    end
  end



end
