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

  describe "#submitted" do
    let(:mail) { ReportMailer.with(user: user, report: report).submitted }

    context "when the user is a delivery partner in the organisation that the report belongs to" do
      let(:user) { create(:administrator, organisation: organisation) }

      it "sends the email to the user's email address" do
        expect(mail.to).to eq([user.email])
      end

      it "has the correct title" do
        expect(mail.subject).to eq("Report your Official Development Assistance - Your report has been submitted")
      end

      it "contains the report's details" do
        expect(mail.body).to include("Report: FQ4 2020-2021 GCRF ABC")
        expect(mail.body).to include("Link to report: http://test.local/reports/#{report.id}")
      end

      it "contains the expected body" do
        expect(mail.body).to include("BEIS have received your report")
      end
    end

    context "when the user is a service owner" do
      let(:user) { create(:beis_user) }

      it "sends the email to the user's email address" do
        expect(mail.to).to eq([user.email])
      end

      it "has the correct title" do
        expect(mail.subject).to eq("Report your Official Development Assistance - A delivery partner has submitted a report")
      end

      it "contains the report's details" do
        expect(mail.body).to include("Report: FQ4 2020-2021 GCRF ABC")
        expect(mail.body).to include("Link to report: http://test.local/reports/#{report.id}")
      end

      it "contains the expected body" do
        expect(mail.body).to include("A delivery partner has submitted a report.")
      end
    end

    context "when the user is a delivery partner in a different organisation" do
      let(:user) { create(:administrator) }

      it "should raise an error" do
        expect { mail.body }.to raise_error(ArgumentError, "User must either be a service owner or belong to the organisation making the report")
      end
    end
  end

  describe "#approved" do
    let(:mail) { ReportMailer.with(user: user, report: report).approved }

    it "sends the email to the user's email address" do
      expect(mail.to).to eq([user.email])
    end

    it "has the correct title" do
      expect(mail.subject).to eq("Report your Official Development Assistance - Your report has been approved")
    end

    it "contains the report's details" do
      expect(mail.body).to include("Report: FQ4 2020-2021 GCRF ABC")
      expect(mail.body).to include("Link to report: http://test.local/reports/#{report.id}")
    end

    it "contains the expected body" do
      expect(mail.body).to include("BEIS have approved your report.")
    end
  end
end
