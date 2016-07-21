class Admin < ActiveRecord::Base
  validates_inclusion_of :singleton_guard, in: [0]

  def self.instance
    # there will be only one row, and its ID must be '1'
    begin
      find(1)
    rescue ActiveRecord::RecordNotFound
      # slight race condition here, but it will only happen once
      row = Admin.new
      row.singleton_guard = 0
      row.save!
      row
    end
  end

end
