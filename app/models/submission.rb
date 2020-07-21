class Submission < ApplicationRecord
  include PublicActivity::Common

  validates_presence_of :description
  validates_presence_of :state

  belongs_to :fund, -> { where(level: :fund) }, class_name: "Activity"
  belongs_to :organisation

  validates_uniqueness_of :fund, scope: :organisation
  validate :activity_must_be_a_fund

  enum state: [:inactive]

  def activity_must_be_a_fund
    return unless fund.present?
    unless fund.fund?
      errors.add(:fund, I18n.t("activerecord.errors.models.submission.attributes.fund.level"))
    end
  end
end
