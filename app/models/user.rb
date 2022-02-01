class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :rememberable, :validatable
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

  private

  def email_cannot_be_changed_after_create
    if email_changed?
      errors.add(:email, :cannot_be_changed)
    end
  end
end
