require 'daru/view'

class Visualization

  include ActiveModel::Model

  def self.lineChart_demo
    Daru::View::Plot.new([43934, 52503, 57177, 69658, 97031, 119931, 137133, 154175])
  end

  def persisted?
    false
  end

end