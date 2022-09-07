require "rails_helper"

RSpec.describe Report::SendStateChangeEmails do
  subject { described_class.new(report) }

  let!(:report) { create(:report, state: state) }
  let!(:partner_organisation_users) { create_list(:administrator, 5, organisation: report.organisation) }
  let!(:inactive_po_user) { create(:administrator, organisation: report.organisation, active: false) }
  let!(:service_owners) { create_list(:beis_user, 2) }
  let!(:inactive_service_owner) { create(:beis_user, active: false) }

  let(:recipients) { ActionMailer::Base.deliveries.map { |delivery| delivery.to }.flatten }

  context "when the state is active" do
    let(:state) { "active" }

    it "sends the activation emails to the active partner organisation users" do
      expect { subject.send! }.to have_enqueued_mail(ReportMailer, :activated).exactly(partner_organisation_users.count).times

      perform_enqueued_jobs

      expect(recipients).to match_array(partner_organisation_users.pluck(:email))
    end
  end

  context "when the state is submitted" do
    let(:state) { "submitted" }

    it "sends the submitted emails to the active partner organisation users and service owners" do
      expect { subject.send! }.to have_enqueued_mail(ReportMailer, :submitted)
        .exactly((service_owners + partner_organisation_users).count).times

      perform_enqueued_jobs

      expect(recipients).to match_array((service_owners + partner_organisation_users).pluck(:email))
    end
  end

  context "when the state is awaiting_changes" do
    let(:state) { "awaiting_changes" }

    it "sends the awaiting changes emails to the active partner organisation users" do
      expect { subject.send! }.to have_enqueued_mail(ReportMailer, :awaiting_changes).exactly(partner_organisation_users.count).times

      perform_enqueued_jobs

      expect(recipients).to match_array(partner_organisation_users.pluck(:email))
    end
  end

  context "when the state is approved" do
    let(:state) { "approved" }

    it "sends the approved emails to the active partner organisation users and service owners" do
      expect { subject.send! }.to have_enqueued_mail(ReportMailer, :approved)
        .exactly((service_owners + partner_organisation_users).count).times

      perform_enqueued_jobs

      expect(recipients).to match_array((service_owners + partner_organisation_users).pluck(:email))
    end
  end
end
