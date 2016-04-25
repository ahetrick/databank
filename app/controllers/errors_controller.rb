class ErrorsController < ApplicationController
  def routing
    redirect_to ('/404.html')
  end
end