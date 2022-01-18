require "rails_helper"

RSpec.describe DownloadLinkMailer, type: :mailer, wip: true do
  describe "#send_link(recipient:, file_url:, file_name:)" do
    let(:user) { double("beis user", email: "beis@example.com") }

    let(:mail) do
      DownloadLinkMailer.send_link(
        recipient: user,
        file_url: "https://roda.example.com/abc123",
        file_name: "spending_breakdown.csv"
      )
    end

    it "includes a message with the export's filename" do
      expect(mail.body).to include(
        "You may download the requested export ('spending_breakdown.csv') from:"
      )
    end

    it "includes the given url as a link to download the export" do
      expect(mail.body).to include("https://roda.example.com/abc123")
    end

    it "sends the email to the given recipient" do
      expect(mail.to).to include("beis@example.com")
    end

    it "sets a helpful subject on the email" do
      expect(mail.subject).to eq(
        "Report your Official Development Assistance - " \
        "Your export 'spending_breakdown.csv' is ready to download"
      )
    end

    it "includes a request for info in the event of a problem" do
      expect(mail.body).to include(
        "If you experience any difficulties downloading your export, " \
        "please let us know. Please include the download link and " \
        "the export's filename in your report."
      )
    end

    it "includes contact details for getting in touch" do
      expect(mail.body).to include("support@beisodahelp.zendesk.com")
    end

    it "includes a link for requesting support" do
      expect(mail.body).to include("https://beisodahelp.zendesk.com")
    end
  end
end
