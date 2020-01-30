class User < ApplicationRecord
  belongs_to :organisation
  validates_presence_of :name, :email

  enum role: {
    administrator: "administrator",
    delivery_partner: "delivery_partner",
    fund_manager: "fund_manager",
  }

  attribute :role, :string, default: "delivery_partner"

  FORM_FIELD_TRANSLATIONS = {
    organisation_id: :organisation,
  }.freeze

  def role_name
    I18n.t("activerecord.attributes.user.roles.#{role}")
  end
end
