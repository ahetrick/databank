class Definition < ActiveRecord::Base
  def to_param
    self.term
  end
end
