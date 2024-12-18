class User < ApplicationRecord
  devise :two_factor_authenticatable, :rememberable, :secure_validatable, :recoverable,
    otp_secret_encryption_key: ENV["SECRET_KEY_BASE"]

  belongs_to :organisation
  has_and_belongs_to_many :additional_organisations, class_name: "Organisation", join_table: "organisations_users"
  has_many :historical_events
  validates_presence_of :name, :email
  validates :email, with: :email_cannot_be_changed_after_create, on: :update

  before_save :ensure_otp_secret!, if: -> { otp_required_for_login && otp_secret.nil? }

  FORM_FIELD_TRANSLATIONS = {
    organisation_id: :organisation
  }.freeze

  scope :active, -> { where(deactivated_at: nil) }
  scope :deactivated, -> { where.not(deactivated_at: nil) }

  scope :all_active, -> {
    active.includes(:organisation).joins(:organisation).order("organisations.name ASC, users.name ASC")
  }
  scope :all_deactivated, -> {
    deactivated.includes(:organisation).joins(:organisation).order("users.deactivated_at ASC, organisations.name ASC, users.name ASC")
  }

  delegate :service_owner?, :partner_organisation?, to: :organisation

  def active
    deactivated_at.blank?
  end
  alias_method :active?, :active

  def organisation
    if Current.user_organisation
      return Organisation.find(Current.user_organisation)
    end
    super
  end

  def primary_organisation
    Organisation.find(organisation_id)
  end

  def all_organisations
    Organisation.where(id: [organisation_id, additional_organisations.map(&:id)].flatten)
  end

  def additional_organisations?
    additional_organisations.any?
  end

  def current_organisation_id
    Current.user_organisation || organisation.id
  end

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
    if email.to_s.squish.downcase != email_was.to_s.squish.downcase
      errors.add(:email, :cannot_be_changed)
    end
  end
end
