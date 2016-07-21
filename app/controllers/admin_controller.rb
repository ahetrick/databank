class AdminController < ApplicationController
  before_action :set_admin, only: [:show, :edit, :update, :destroy]

  # GET /admin
  # GET /admin.json
  def index
    @admin = Admin.instance
  end

  # GET /admin/1
  # GET /admin/1.json
  def show
    @admin = Admin.instance
  end

  # GET /admin/new
  def new
    @admin = Admin.instance
  end

  # GET /admin/1/edit
  def edit
    @admin = Admin.instance
  end

  # POST /admin
  # POST /admin.json
  def create
    @admin = Admin.instance

    respond_to do |format|
      if @admin.save
        format.html { redirect_to @admin, notice: 'Admin was successfully created.' }
        format.json { render :show, status: :created, location: @admin }
      else
        format.html { render :new }
        format.json { render json: @admin.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/1
  # PATCH/PUT /admin/1.json
  def update
    respond_to do |format|
      if @admin.update(admin_params)
        format.html { redirect_to @admin, notice: 'Admin was successfully updated.' }
        format.json { render :show, status: :ok, location: @admin }
      else
        format.html { render :edit }
        format.json { render json: @admin.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/1
  # DELETE /admin/1.json
  def destroy
    @admin.destroy
    respond_to do |format|
      format.html { redirect_to admin_index_url, notice: 'Admin was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin
      @admin = Admin.instance
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def admin_params
      params.require(:admin).permit(:read_only_alert)
    end
end
