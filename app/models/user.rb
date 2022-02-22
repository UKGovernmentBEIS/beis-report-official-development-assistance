class User < ApplicationRecord
  devise :two_factor_authenticatable, :rememberable, :validatable, :recoverable,
    otp_secret_encryption_key: ENV["SECRET_KEY_BASE"]

  belongs_to :organisation
  has_many :historical_events
  validates_presence_of :name, :email
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :email, with: :email_cannot_be_changed_after_create, on: :update

  FORM_FIELD_TRANSLATIONS = {
    organisation_id: :organisation
  }.freeze

  scope :active, -> { where(active: true) }

  delegate :service_owner?, :delivery_partner?, to: :organisation

  def active_for_authentication?
    active
  end

  private

  def email_cannot_be_changed_after_create
    if email_changed?
      errors.add(:email, :cannot_be_changed)
    end
  end
end
