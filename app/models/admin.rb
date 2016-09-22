class Admin < ActiveRecord::Base
  validates_inclusion_of :singleton_guard, in: [0]

  def self.instance
    # there will be only one row, and its ID must be '1'
    if Admin.all.count == 1
      return Admin.all.first
    else
      Admin.destroy_all
      admin = Admin.create(singleton_guard: 0)
      return admin
    end

  end

end
