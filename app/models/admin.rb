# frozen_string_literal: true

# Interface for service message(s)
# TODO: call this something else
class Admin < ActiveRecord::Base
  validates_inclusion_of :singleton_guard, in: [0]

  # there must be only one Admin record
  def self.instance
    admin_count = Admin.all.count
    return Admin.all.first if admin_count == 1

    Admin.destroy_all if admin_count > 1
    # at this point, there are zero Admin instances
    Admin.create(singleton_guard: 0)
  end
end
