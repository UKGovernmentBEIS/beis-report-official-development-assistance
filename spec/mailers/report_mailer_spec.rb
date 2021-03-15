require "rails_helper"

RSpec.describe ReportMailer, type: :mailer do
  let(:fund) { create(:fund_activity, :gcrf) }
  let(:organisation) { create(:organisation, beis_organisation_reference: "ABC") }
  let(:user) { create(:administrator) }
  let(:report) { create(:report, financial_quarter: 4, financial_year: 2020, deadline: DateTime.parse("2021-01-01"), fund: fund, organisation: organisation) }

  describe "#activated" do
    let(:mail) { ReportMailer.with(user: user, report: report).activated }

    it "sends the email to the user's email address" do
      expect(mail.to).to eq([user.email])
    end

    it "has the correct title" do
      expect(mail.subject).to eq("Report your Official Development Assistance - A report has been activated")
    end

    it "contains the report's details" do
      expect(mail.body).to include("Report: FQ4 2020-2021 GCRF ABC")
      expect(mail.body).to include("Deadline for submission: 1 Jan 2021")
      expect(mail.body).to include("Link to report: http://test.local/reports/#{report.id}")
    end
  end
end
