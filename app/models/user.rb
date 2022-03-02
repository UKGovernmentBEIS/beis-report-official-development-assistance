class User < ApplicationRecord
  devise :two_factor_authenticatable, :rememberable, :validatable, :recoverable,
    otp_secret_encryption_key: ENV["SECRET_KEY_BASE"]

  belongs_to :organisation
  has_many :historical_events
  validates_presence_of :name, :email
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :email, with: :email_cannot_be_changed_after_create, on: :update

  before_save :ensure_otp_secret!, if: -> { otp_required_for_login && otp_secret.nil? }

  FORM_FIELD_TRANSLATIONS = {
    organisation_id: :organisation
  }.freeze

  scope :active, -> { where(active: true) }

  delegate :service_owner?, :delivery_partner?, to: :organisation

  def active_for_authentication?
    active
  end

  def confirmed_for_mfa?
    mobile_number.present? && mobile_number_confirmed_at.present?
  end

  private

  def ensure_otp_secret!
    self.otp_secret = User.generate_otp_secret
  end

  def email_cannot_be_changed_after_create
    if email_changed?
      errors.add(:email, :cannot_be_changed)
    end
  end
end
