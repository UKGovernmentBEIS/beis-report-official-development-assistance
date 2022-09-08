require "factory_bot"

class ReportMailerPreview < ActionMailer::Preview
  def activated
    ReportMailer.with(
      user: FactoryBot.build(:administrator),
      report: FactoryBot.build_stubbed(:report, :active, id: SecureRandom.uuid)
    ).activated
  end

  def submitted_partner_organisation
    organisation = FactoryBot.build(:partner_organisation)

    ReportMailer.with(
      user: FactoryBot.build(:administrator, organisation: organisation),
      report: FactoryBot.build_stubbed(:report, :submitted, id: SecureRandom.uuid, organisation: organisation)
    ).submitted
  end

  def submitted_service_owner
    ReportMailer.with(
      user: FactoryBot.build(:beis_user),
      report: FactoryBot.build_stubbed(:report, :submitted, id: SecureRandom.uuid)
    ).submitted
  end

  def approved
    ReportMailer.with(
      user: FactoryBot.build(:administrator),
      report: FactoryBot.build_stubbed(:report, :approved, id: SecureRandom.uuid)
    ).approved
  end

  def awaiting_changes
    ReportMailer.with(
      user: FactoryBot.build(:administrator),
      report: FactoryBot.build_stubbed(:report, :approved, id: SecureRandom.uuid)
    ).awaiting_changes
  end
end
