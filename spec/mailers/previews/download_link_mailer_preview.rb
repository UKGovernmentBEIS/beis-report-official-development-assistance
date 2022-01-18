require "factory_bot"

class DownloadLinkMailerPreview < ActionMailer::Preview
  def send_link
    DownloadLinkMailer.send_link(
      recipient: FactoryBot.build(:beis_user, email: "beis@example.com"),
      file_url: "https://roda.example.com/abc123",
      file_name: "spending_breakdown.csv"
    )
  end

  def send_failure_notification
    DownloadLinkMailer.send_failure_notification(
      recipient: FactoryBot.build(:beis_user, email: "beis@example.com")
    )
  end
end
