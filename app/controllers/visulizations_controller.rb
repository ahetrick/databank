Daru::View.plotting_library = :highcharts

class VisulizationsController < ApplicationController
  def index
    @lineChart_demo = Visualization.lineChart_demo
  end
end