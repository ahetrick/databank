class IdentityError < StandardError
  def initialize(msg="Could not confirm identity.")
    super
  end
end

raise IdentityError