class Identity < OmniAuth::Identity::Models::ActiveRecord

  attr_accessor :remember_token, :activation_token, :reset_token

  before_create :set_invitee
  before_create :create_activation_digest
  validates :name,  presence: true
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
            format: { with: VALID_EMAIL_REGEX },
            uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }

  # Returns true if the given token matches the digest.
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # Returns the hash digest of the given string.
  def self.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
               BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

# Returns a random token.
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  private

  # Converts email to all lower-case.
  def downcase_email
    self.email = email.downcase
  end

  def set_invitee
    invitee = Invitee.find_by_email(self.email)
    if invitee
      self.invitee_id = invitee.id
    else
      raise("attempt to create identity without invitee: #{self.to_yaml}")
    end
  end

  # Creates and assigns the activation token and digest.
  def create_activation_digest
    self.activation_token  = Identity.new_token
    self.activation_digest = Identity.digest(activation_token)
  end

end
