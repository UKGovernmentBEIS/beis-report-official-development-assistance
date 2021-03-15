require "factory_bot"

class ReportMailerPreview < ActionMailer::Preview
  def activated
    ReportMailer.with(
      user: FactoryBot.build(:administrator),
      report: FactoryBot.build_stubbed(:report, :active, id: SecureRandom.uuid)
    ).activated
  end
end
