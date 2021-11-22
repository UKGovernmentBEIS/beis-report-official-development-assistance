require "rails_helper"

RSpec.describe ReportPolicy do
  subject { described_class.new(user, report) }

  context "as a BEIS user" do
    let(:user) { build_stubbed(:beis_user) }
    let(:report) { create(:report) }

    it "includes all reports in the resolved scope" do
      report = create(:report)
      another_report = create(:report)
      resolved_scope = described_class::Scope.new(user, Report).resolve

      expect(resolved_scope).to include report, another_report
    end

    context "when the report is active" do
      before { report.update(state: :active) }

      it "controls actions as expected" do
        is_expected.to permit_action(:create)
        is_expected.to permit_action(:upload_history)

        is_expected.to forbid_action(:change_state)
        is_expected.to forbid_action(:activate)
        is_expected.to forbid_action(:submit)
        is_expected.to forbid_action(:request_changes)
        is_expected.to forbid_action(:review)
        is_expected.to forbid_action(:approve)
        is_expected.to forbid_action(:upload)
      end
    end

    context "when the report is submitted" do
      before { report.update(state: :submitted) }

      it "controls actions as expected" do
        is_expected.to permit_action(:change_state)
        is_expected.to permit_action(:review)

        is_expected.to forbid_action(:activate)
        is_expected.to forbid_action(:submit)
        is_expected.to forbid_action(:request_changes)
        is_expected.to forbid_action(:approve)
        is_expected.to forbid_action(:upload)
        is_expected.to forbid_action(:upload_history)
      end
    end

    context "when the report is in review" do
      before { report.update(state: :in_review) }

      it "controls actions as expected" do
        is_expected.to permit_action(:change_state)
        is_expected.to permit_action(:request_changes)
        is_expected.to permit_action(:approve)

        is_expected.to forbid_action(:activate)
        is_expected.to forbid_action(:submit)
        is_expected.to forbid_action(:review)
        is_expected.to forbid_action(:upload)
        is_expected.to forbid_action(:upload_history)
      end
    end

    context "when the report is awaiting changes" do
      before { report.update(state: :awaiting_changes) }

      it "controls actions as expected" do
        is_expected.to forbid_action(:change_state)
        is_expected.to forbid_action(:activate)
        is_expected.to forbid_action(:submit)
        is_expected.to forbid_action(:request_changes)
        is_expected.to forbid_action(:review)
        is_expected.to forbid_action(:approve)
        is_expected.to forbid_action(:upload)

        is_expected.to permit_action(:upload_history)
      end
    end

    context "when the report is approved" do
      before { report.update(state: :approved) }

      it "controls actions as expected" do
        is_expected.to forbid_action(:change_state)
        is_expected.to forbid_action(:activate)
        is_expected.to forbid_action(:submit)
        is_expected.to forbid_action(:request_changes)
        is_expected.to forbid_action(:review)
        is_expected.to forbid_action(:approve)
        is_expected.to forbid_action(:upload)
        is_expected.to forbid_action(:upload_history)
      end
    end
  end

  context "as a Delivery partner user" do
    let(:user) { build_stubbed(:delivery_partner_user) }

    it "includes only reports that the users organisation is reporting in the resolved scope" do
      report = create(:report, organisation: user.organisation)
      _another_report = create(:report)
      resolved_scope = described_class::Scope.new(user, Report).resolve

      expect(resolved_scope).to contain_exactly report
    end

    context "when the report does not belong to the user's organisation" do
      let(:report) { create(:report) }

      it "controls actions as expected" do
        is_expected.to forbid_action(:update)
        is_expected.to forbid_action(:create)
        is_expected.to forbid_action(:change_state)
        is_expected.to forbid_action(:destroy)
        is_expected.to forbid_action(:activate)
        is_expected.to forbid_action(:submit)
        is_expected.to forbid_action(:review)
        is_expected.to forbid_action(:request_changes)
        is_expected.to forbid_action(:approve)
        is_expected.to forbid_action(:upload)
        is_expected.to forbid_action(:upload_history)

        is_expected.to permit_action(:index)
      end
    end

    context "when the report belongs to the user's organisation" do
      let(:report) { create(:report, organisation: user.organisation) }

      context "when the report is active" do
        before { report.update(state: :active) }

        it "controls actions as expected" do
          is_expected.to forbid_action(:create)

          is_expected.to permit_action(:show)
          is_expected.to permit_action(:download)
          is_expected.to permit_action(:change_state)
          is_expected.to permit_action(:submit)
          is_expected.to permit_action(:upload)

          is_expected.to forbid_action(:activate)
          is_expected.to forbid_action(:review)
          is_expected.to forbid_action(:request_changes)
          is_expected.to forbid_action(:approve)
          is_expected.to forbid_action(:upload_history)
        end
      end

      context "when the report is submitted" do
        before { report.update(state: :submitted) }

        it "controls actions as expected" do
          is_expected.to permit_action(:show)
          is_expected.to permit_action(:download)

          is_expected.to forbid_action(:change_state)
          is_expected.to forbid_action(:activate)
          is_expected.to forbid_action(:submit)
          is_expected.to forbid_action(:review)
          is_expected.to forbid_action(:request_changes)
          is_expected.to forbid_action(:approve)
          is_expected.to forbid_action(:upload)
          is_expected.to forbid_action(:upload_history)
        end
      end

      context "when the report is in review" do
        before { report.update(state: :in_review) }

        it "controls actions as expected" do
          is_expected.to permit_action(:show)
          is_expected.to permit_action(:download)

          is_expected.to forbid_action(:change_state)
          is_expected.to forbid_action(:activate)
          is_expected.to forbid_action(:submit)
          is_expected.to forbid_action(:review)
          is_expected.to forbid_action(:request_changes)
          is_expected.to forbid_action(:approve)
          is_expected.to forbid_action(:upload)
          is_expected.to forbid_action(:upload_history)
        end
      end

      context "when the report is awaiting changes" do
        before { report.update(state: :awaiting_changes) }

        it "controls actions as expected" do
          is_expected.to permit_action(:show)
          is_expected.to permit_action(:download)
          is_expected.to permit_action(:change_state)
          is_expected.to permit_action(:submit)
          is_expected.to permit_action(:upload)

          is_expected.to forbid_action(:activate)
          is_expected.to forbid_action(:review)
          is_expected.to forbid_action(:request_changes)
          is_expected.to forbid_action(:approve)
          is_expected.to forbid_action(:upload_history)
        end
      end

      context "when the report is approved" do
        before { report.update(state: :approved) }

        it "controls actions as expected" do
          is_expected.to permit_action(:show)
          is_expected.to permit_action(:download)

          is_expected.to forbid_action(:change_state)
          is_expected.to forbid_action(:activate)
          is_expected.to forbid_action(:submit)
          is_expected.to forbid_action(:request_changes)
          is_expected.to forbid_action(:review)
          is_expected.to forbid_action(:approve)
          is_expected.to forbid_action(:upload)
          is_expected.to forbid_action(:upload_history)
        end
      end
    end
  end
end
