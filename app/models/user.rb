class User < ApplicationRecord
  include PublicActivity::Common

  belongs_to :organisation
  validates_presence_of :name, :email
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :email, with: :email_cannot_be_changed_after_create, on: :update

  enum role: {
    administrator: "administrator",
  }

  attribute :role, :string, default: "administrator"

  FORM_FIELD_TRANSLATIONS = {
    organisation_id: :organisation,
  }.freeze

  def role_name
    I18n.t("activerecord.attributes.user.roles.#{role}")
  end

  def service_owner?
    organisation.service_owner?
  end

  def delivery_partner?
    !service_owner?
  end

  private

  def email_cannot_be_changed_after_create
    if email_changed?
      errors.add(:email, :cannot_be_changed)
    end
  end
end
