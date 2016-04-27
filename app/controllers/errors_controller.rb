class ErrorsController < ApplicationController
  def error404
    respond_to do |format|
      format.html { render ('errors/error404'), status: 404}
      format.all { render nothing: true, status: 404 }
    end
  end
end