require "rails_helper"

RSpec.describe ActivityDefaults do
  let(:beis) { create(:beis_organisation) }
  let(:partner_organisation) { create(:partner_organisation) }

  let(:fund) { create(:fund_activity, :gcrf) }
  let(:programme) { create(:programme_activity, :gcrf_funded, parent: fund) }
  let(:project) { create(:project_activity, :gcrf_funded, parent: programme) }
  let(:third_party_project) { create(:third_party_project_activity, :gcrf_funded, parent: project) }

  let!(:current_report) { create(:report, :active, organisation: partner_organisation, fund: fund) }

  before do
    # some reports which we don't expect to be returned as 'originating_report'
    # for 'project' (level C)
    _other_org = create(:report, :active, organisation: create(:partner_organisation), fund: fund)
    _other_fund = create(:report, :active, organisation: partner_organisation, fund: create(:fund_activity, :newton))
    _approved = create(:report, :approved, organisation: partner_organisation, fund: fund)
  end

  describe "#call" do
    let(:activity_defaults) do
      described_class.new(
        parent_activity: parent_activity,
        partner_organisation: partner_organisation
      )
    end

    subject { activity_defaults.call }

    context "parent is a fund" do
      let(:parent_activity) { fund }

      it "sets level to 'programme'" do
        expect(subject[:level]).to eq("programme")
      end

      it "sets the parent to the parent activity" do
        expect(subject[:parent_id]).to eq(fund.id)
      end

      it "sets the source_fund_code to the parent activity's source fund id" do
        expect(subject[:source_fund_code]).to eq(fund.source_fund.id)
      end

      it "sets the organisation to BEIS" do
        expect(subject[:organisation_id]).to eq(beis.id)
      end

      it "sets the extending organisation to the partner organisation" do
        expect(subject[:extending_organisation_id]).to eq(partner_organisation.id)
      end

      it "sets the form_state to 'is_oda', as we already have the level and parent" do
        expect(subject[:form_state]).to eq("is_oda")
      end

      it "sets the originating_report id to nil, as level A does not report" do
        expect(subject[:origination_report_id]).to be_nil
      end

      it "sets the roda identifier" do
        identifier_parts = subject[:roda_identifier].split("-")

        expect(identifier_parts.count).to eq(3)
        expect(identifier_parts.first).to eq(fund.roda_identifier)
        expect(identifier_parts.second).to eq(partner_organisation.beis_organisation_reference)
        expect(identifier_parts.third).to match(/[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{7}/)
      end

      it "sets the transparency identifier" do
        expect(subject[:transparency_identifier]).to eq("#{Organisation::SERVICE_OWNER_IATI_REFERENCE}-#{subject[:roda_identifier]}")
      end
    end

    context "parent is a programme" do
      let(:parent_activity) { programme }

      it "sets level to 'project'" do
        expect(subject[:level]).to eq("project")
      end

      it "sets the parent to the parent activity" do
        expect(subject[:parent_id]).to eq(programme.id)
      end

      it "sets the source_fund_code to the parent activity's source fund id" do
        expect(subject[:source_fund_code]).to eq(programme.source_fund.id)
      end

      it "sets the organisation to the partner organisation" do
        expect(subject[:organisation_id]).to eq(partner_organisation.id)
      end

      it "sets the extending organisation to the partner organisation" do
        expect(subject[:extending_organisation_id]).to eq(partner_organisation.id)
      end

      it "sets the form_state to 'is_oda', as we already have the level and parent" do
        expect(subject[:form_state]).to eq("is_oda")
      end

      it "sets the originating_report id to nil, as level B does not report" do
        expect(subject[:origination_report_id]).to be_nil
      end

      it "sets the roda identifier" do
        identifier_parts = subject[:roda_identifier].split("-")

        expect(identifier_parts.count).to eq(4)
        expect([
          identifier_parts.first,
          identifier_parts.second,
          identifier_parts.third
        ].join("-")).to eq(programme.roda_identifier)
        expect(identifier_parts.third).to match(/[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{7}/)
      end

      it "sets the transparency identifier" do
        expect(subject[:transparency_identifier]).to eq("#{Organisation::SERVICE_OWNER_IATI_REFERENCE}-#{subject[:roda_identifier]}")
      end
    end

    context "parent is a project" do
      let(:parent_activity) { project }

      it "sets level to 'third_party_project'" do
        expect(subject[:level]).to eq("third_party_project")
      end

      it "sets the parent to the parent activity" do
        expect(subject[:parent_id]).to eq(project.id)
      end

      it "sets the source_fund_code to the parent activity's source fund id" do
        expect(subject[:source_fund_code]).to eq(fund.source_fund.id)
      end

      it "sets the organisation to the partner organisation" do
        expect(subject[:organisation_id]).to eq(partner_organisation.id)
      end

      it "sets the extending organisation to the partner organisation" do
        expect(subject[:extending_organisation_id]).to eq(partner_organisation.id)
      end

      it "sets the form_state to 'is_oda', as we already have the level and parent" do
        expect(subject[:form_state]).to eq("is_oda")
      end

      it "sets the originating_report id to the report for the current financial period" do
        expect(subject[:originating_report_id]).to eq(current_report.id)
      end

      it "sets the roda identifier" do
        identifier_parts = subject[:roda_identifier].split("-")

        expect(identifier_parts.count).to eq(5)
        expect([
          identifier_parts.first,
          identifier_parts.second,
          identifier_parts.third,
          identifier_parts.fourth
        ].join("-")).to eq(project.roda_identifier)
        expect(identifier_parts.fourth).to match(/[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{7}/)
      end

      it "sets the transparency identifier" do
        expect(subject[:transparency_identifier]).to eq("#{Organisation::SERVICE_OWNER_IATI_REFERENCE}-#{subject[:roda_identifier]}")
      end
    end

    context "when an activity already exists with the same RODA identifier" do
      let(:parent_activity) { project }

      let(:existing_roda_identifier) { "ABC-1234" }
      let(:new_roda_identifier) { "ABC-5678" }
      let!(:existing_activity) { create(:programme_activity, roda_identifier: existing_roda_identifier) }

      before do
        allow(activity_defaults).to receive(:generate_roda_identifier).and_return(existing_roda_identifier, new_roda_identifier)
      end

      it "generates a unique roda identifier" do
        expect(subject[:roda_identifier]).to eq(new_roda_identifier)
      end
    end
  end

  describe "#initialize" do
    it "raises an exception if parent_activity parameter is not an instance of Activity" do
      expect { described_class.new(parent_activity: Class.new, partner_organisation: partner_organisation) }
        .to raise_error(described_class::InvalidParentActivity)
    end

    it "raises an exception if parent_activity is a third-party project" do
      expect { described_class.new(parent_activity: third_party_project, partner_organisation: partner_organisation) }
        .to raise_error(described_class::InvalidParentActivity)
    end

    it "raises an exception if partner_organisation parameter is not an instance of Organisation" do
      expect { described_class.new(parent_activity: programme, partner_organisation: Class.new) }
        .to raise_error(described_class::InvalidPartnerOrganisation)
    end

    it "raises an exception if partner_organisation is BEIS" do
      expect { described_class.new(parent_activity: fund, partner_organisation: beis) }
        .to raise_error(described_class::InvalidPartnerOrganisation)
    end
  end
end
