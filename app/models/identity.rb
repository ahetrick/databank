
class Identity < OmniAuth::Identity::Models::ActiveRecord

  attr_accessor :remember_token, :activation_token, :reset_token

  before_create :set_invitee
  before_create :create_activation_digest
  after_create :send_activation_email

  before_destroy :destroy_user

  validates :name,  presence: true
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
            format: { with: VALID_EMAIL_REGEX },
            uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }
  validate :invited

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

  def invited
    set_invitee
    errors.add(:base, 'Registered identity must have current invitation.') unless [nil, ''].exclude?(self.invitee_id)
  end

  def activation_url
    "#{IDB_CONFIG[:root_url_text]}/account_activations/#{self.activation_token}/edit?email=#{CGI.escape(self.email)}"
  end

  def send_activation_email
    notification = DatabankMailer.account_activation(self)
    notification.deliver_now
  end

  def group
    set_invitee
    if @invitee
      @invitee.group
    else
      nil
    end
  end

  private

  # Converts email to all lower-case.
  def downcase_email
    self.email = email.downcase
  end

  def destroy_user
    user = User::Identity.find_by_email(self.email)
    if user
      user.destroy!
    end
  end

  def set_invitee
    @invitee = Invitee.find_by_email(self.email)
    if @invitee && @invitee.expires_at > Time.now
      self.invitee_id = @invitee.id
    end
  end

  # Creates and assigns the activation token and digest.
  def create_activation_digest
    self.activation_token  = Identity.new_token
    self.activation_digest = Identity.digest(activation_token)
  end

end
