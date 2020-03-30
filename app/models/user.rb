class User < ApplicationRecord
  include PublicActivity::Model
  tracked owner: proc { |controller, _model| controller.current_user }

  belongs_to :organisation
  validates_presence_of :name, :email
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}

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
end
