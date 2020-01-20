class User < ApplicationRecord
  has_and_belongs_to_many :organisations
  validates_presence_of :name, :email
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}

  enum role: {
    administrator: "administrator",
    delivery_partner: "delivery_partner",
    fund_manager: "fund_manager",
  }

  attribute :role, :string, default: "delivery_partner"

  def role_name
    I18n.t("activerecord.attributes.user.roles.#{role}")
  end
end
