class IllinoisExpertsController < ApplicationController
  def index
    @datasets=Datasets.all
  end
end