require "rails_helper"

RSpec.describe ReportMailer, type: :mailer do
  let(:fund) { create(:fund_activity, :gcrf) }
  let(:organisation) { create(:partner_organisation, beis_organisation_reference: "ABC") }
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

    context "when the user is inactive" do
      before do
        user.update!(deactivated_at: DateTime.yesterday)
      end

      it "should raise an error" do
        expect { mail.body }.to raise_error(ArgumentError, "User must be active to receive report-related emails")
      end
    end

    context "when the email is from the training site" do
      it "includes the site in the email subject" do
        ClimateControl.modify DOMAIN: "https://training.report-official-development-assistance.service.gov.uk" do
          expect(mail.subject).to eq("[Training] Report your Official Development Assistance - A report has been activated")
        end
      end
    end

    context "when the email is from the production site" do
      it "does not include the site in the email subject" do
        ClimateControl.modify DOMAIN: "https://www.report-official-development-assistance.service.gov.uk" do
          expect(mail.subject).to eq("Report your Official Development Assistance - A report has been activated")
        end
      end
    end
  end

  describe "#submitted" do
    let(:mail) { ReportMailer.with(user: user, report: report).submitted }

    context "when the user is a partner organisation user in the organisation that the report belongs to" do
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

      context "when the email is from the training site" do
        it "includes the site in the email subject" do
          ClimateControl.modify DOMAIN: "https://training.report-official-development-assistance.service.gov.uk" do
            expect(mail.subject).to eq("[Training] Report your Official Development Assistance - Your report has been submitted")
          end
        end
      end

      context "when the email is from the production site" do
        it "does not include the site in the email subject" do
          ClimateControl.modify DOMAIN: "https://www.report-official-development-assistance.service.gov.uk" do
            expect(mail.subject).to eq("Report your Official Development Assistance - Your report has been submitted")
          end
        end
      end
    end

    context "when the user is a service owner" do
      let(:user) { create(:beis_user) }

      it "sends the email to the user's email address" do
        expect(mail.to).to eq([user.email])
      end

      it "has the correct title" do
        expect(mail.subject).to eq("Report your Official Development Assistance - A partner organisation has submitted a report")
      end

      it "contains the report's details" do
        expect(mail.body).to include("Report: FQ4 2020-2021 GCRF ABC")
        expect(mail.body).to include("Link to report: http://test.local/reports/#{report.id}")
      end

      it "contains the expected body" do
        expect(mail.body).to include("A partner organisation has submitted a report.")
      end

      context "when the email is from the training site" do
        it "includes the site in the email subject" do
          ClimateControl.modify DOMAIN: "https://training.report-official-development-assistance.service.gov.uk" do
            expect(mail.subject).to eq("[Training] Report your Official Development Assistance - A partner organisation has submitted a report")
          end
        end
      end

      context "when the email is from the production site" do
        it "does not include the site in the email subject" do
          ClimateControl.modify DOMAIN: "https://www.report-official-development-assistance.service.gov.uk" do
            expect(mail.subject).to eq("Report your Official Development Assistance - A partner organisation has submitted a report")
          end
        end
      end
    end

    context "when the user is a partner organisation user in a different organisation" do
      let(:user) { create(:administrator, organisation: build(:partner_organisation)) }

      it "should raise an error" do
        expect { mail.body }.to raise_error(ArgumentError, "User must either be a service owner or belong to the organisation making the report")
      end
    end

    context "when the user is inactive" do
      let(:user) { create(:administrator, organisation: organisation, deactivated_at: DateTime.yesterday) }

      it "should raise an error" do
        expect { mail.body }.to raise_error(ArgumentError, "User must be active to receive report-related emails")
      end
    end
  end

  describe "#qa_completed" do
    let(:mail) { ReportMailer.with(user: user, report: report).qa_completed }

    it "sends the email to the user's email address" do
      expect(mail.to).to eq([user.email])
    end

    it "has the correct title" do
      expect(mail.subject).to eq("Report your Official Development Assistance - QA has been completed on a report")
    end

    it "contains the report's details" do
      expect(mail.body).to include("Report: FQ4 2020-2021 GCRF ABC")
      expect(mail.body).to include("Link to report: http://test.local/reports/#{report.id}")
    end

    it "contains the expected body" do
      expect(mail.body).to include("A report has been marked as QA completed.")
      expect(mail.body).to include("The report will need to be approved by the Service Manager and ODA PMO Finance Lead.")
    end

    context "when the user is inactive" do
      before { user.update!(deactivated_at: DateTime.yesterday) }

      it "should raise an error" do
        expect { mail.body }.to raise_error(ArgumentError, "User must be active to receive report-related emails")
      end
    end

    context "when the user is a partner organisation user" do
      let(:user) { create(:partner_organisation_user, organisation: organisation) }

      it "should raise an error" do
        expect { mail.body }.to raise_error(ArgumentError, "User must be a service owner to receive email notification of reports being marked as QA completed")
      end
    end

    context "when the email is from the training site" do
      it "includes the site in the email subject" do
        ClimateControl.modify DOMAIN: "https://training.report-official-development-assistance.service.gov.uk" do
          expect(mail.subject).to eq("[Training] Report your Official Development Assistance - QA has been completed on a report")
        end
      end
    end

    context "when the email is from the production site" do
      it "does not include the site in the email subject" do
        ClimateControl.modify DOMAIN: "https://www.report-official-development-assistance.service.gov.uk" do
          expect(mail.subject).to eq("Report your Official Development Assistance - QA has been completed on a report")
        end
      end
    end
  end

  describe "#approved" do
    let(:mail) { ReportMailer.with(user: user, report: report).approved }

    context "when the user is a partner organisation user in the organisation that the report belongs to" do
      let(:user) { create(:administrator, organisation: organisation) }

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

      context "when the email is from the training site" do
        it "includes the site in the email subject" do
          ClimateControl.modify DOMAIN: "https://training.report-official-development-assistance.service.gov.uk" do
            expect(mail.subject).to eq("[Training] Report your Official Development Assistance - Your report has been approved")
          end
        end
      end

      context "when the email is from the production site" do
        it "does not include the site in the email subject" do
          ClimateControl.modify DOMAIN: "https://www.report-official-development-assistance.service.gov.uk" do
            expect(mail.subject).to eq("Report your Official Development Assistance - Your report has been approved")
          end
        end
      end

      context "when the user is inactive" do
        before do
          user.update!(deactivated_at: DateTime.yesterday)
        end

        it "should raise an error" do
          expect { mail.body }.to raise_error(ArgumentError, "User must be active to receive report-related emails")
        end
      end
    end

    context "when the user is a service owner" do
      let(:user) { create(:beis_user) }

      it "sends the email to the user's email address" do
        expect(mail.to).to eq([user.email])
      end

      it "has the correct title" do
        expect(mail.subject).to eq("Report your Official Development Assistance - A report has been approved")
      end

      it "contains the report's details" do
        expect(mail.body).to include("Report: FQ4 2020-2021 GCRF ABC")
        expect(mail.body).to include("Link to report: http://test.local/reports/#{report.id}")
      end

      it "contains the expected body" do
        expect(mail.body).to include("A report has been approved.")
        expect(mail.body).to include("The CSV file for the approved and locked report is being uploaded")
      end

      context "when the email is from the training site" do
        it "includes the site in the email subject" do
          ClimateControl.modify DOMAIN: "https://training.report-official-development-assistance.service.gov.uk" do
            expect(mail.subject).to eq("[Training] Report your Official Development Assistance - A report has been approved")
          end
        end
      end

      context "when the email is from the production site" do
        it "does not include the site in the email subject" do
          ClimateControl.modify DOMAIN: "https://www.report-official-development-assistance.service.gov.uk" do
            expect(mail.subject).to eq("Report your Official Development Assistance - A report has been approved")
          end
        end
      end
    end

    context "when the user is a partner organisation user in a different organisation" do
      let(:user) { create(:administrator, organisation: build(:partner_organisation)) }

      it "should raise an error" do
        expect { mail.body }.to raise_error(ArgumentError, "User must either be a service owner or belong to the organisation making the report")
      end
    end
  end

  describe "#awaiting_changes" do
    let(:mail) { ReportMailer.with(user: user, report: report).awaiting_changes }

    it "sends the email to the user's email address" do
      expect(mail.to).to eq([user.email])
    end

    it "has the correct title" do
      expect(mail.subject).to eq("Report your Official Development Assistance - A report is awaiting changes")
    end

    it "contains the report's details" do
      expect(mail.body).to include("Report: FQ4 2020-2021 GCRF ABC")
      expect(mail.body).to include("Link to report: http://test.local/reports/#{report.id}")
    end

    it "contains the expected body" do
      expect(mail.body).to include("BEIS have reviewed your report and requested changes.")
    end

    context "when the user is inactive" do
      before do
        user.update!(deactivated_at: DateTime.yesterday)
      end

      it "should raise an error" do
        expect { mail.body }.to raise_error(ArgumentError, "User must be active to receive report-related emails")
      end
    end

    context "when the email is from the training site" do
      it "includes the site in the email subject" do
        ClimateControl.modify DOMAIN: "https://training.report-official-development-assistance.service.gov.uk" do
          expect(mail.subject).to eq("[Training] Report your Official Development Assistance - A report is awaiting changes")
        end
      end
    end

    context "when the email is from the production site" do
      it "does not include the site in the email subject" do
        ClimateControl.modify DOMAIN: "https://www.report-official-development-assistance.service.gov.uk" do
          expect(mail.subject).to eq("Report your Official Development Assistance - A report is awaiting changes")
        end
      end
    end
  end

  describe "#upload_failed" do
    let(:mail) { ReportMailer.with(user: user, report: report).upload_failed }

    it "sends the email to the user's email address" do
      expect(mail.to).to eq([user.email])
    end

    it "has the correct title" do
      expect(mail.subject).to eq("Report your Official Development Assistance - Report upload failed")
    end

    it "contains the report's details" do
      expect(mail.body).to include("FQ4 2020-2021 GCRF ABC")
    end

    it "contains the expected body" do
      expect(mail.body).to include("There has been a problem uploading the CSV for the report")
    end

    context "when the email is from the training site" do
      it "includes the site in the email subject" do
        ClimateControl.modify DOMAIN: "https://training.report-official-development-assistance.service.gov.uk" do
          expect(mail.subject).to eq("[Training] Report your Official Development Assistance - Report upload failed")
        end
      end
    end

    context "when the email is from the production site" do
      it "does not include the site in the email subject" do
        ClimateControl.modify DOMAIN: "https://www.report-official-development-assistance.service.gov.uk" do
          expect(mail.subject).to eq("Report your Official Development Assistance - Report upload failed")
        end
      end
    end

    context "when the user is inactive" do
      before do
        user.update!(deactivated_at: DateTime.yesterday)
      end

      it "should raise an error" do
        expect { mail.body }.to raise_error(ArgumentError, "User must be active to receive report-related emails")
      end
    end

    context "when the user is not a service owner" do
      before do
        user.update!(organisation: organisation)
      end

      it "should raise an error" do
        expect { mail.body }.to raise_error(ArgumentError, "User must be a service owner to receive report upload failure notification emails")
      end
    end
  end
end
