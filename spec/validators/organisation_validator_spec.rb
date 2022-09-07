require "rails_helper"

RSpec.describe OrganisationValidator do
  context "when activity is a fund" do
    subject { build(:fund_activity, organisation: organisation) }

    context "when the organisation is a partner organisation" do
      let(:organisation) { build(:partner_organisation) }

      it { should be_invalid }
    end

    context "when the organisation is the service owner" do
      let(:organisation) { build(:beis_organisation) }

      it { should be_valid }
    end
  end

  context "when activity is a programme" do
    subject { build(:fund_activity, organisation: organisation) }

    context "when the organisation is a partner organisation" do
      let(:organisation) { build(:partner_organisation) }

      it { should be_invalid }
    end

    context "when the organisation is the service owner" do
      let(:organisation) { build(:beis_organisation) }

      it { should be_valid }
    end
  end

  context "when activity is a project" do
    subject { build(:project_activity, organisation: organisation) }

    context "when the organisation is a partner organisation" do
      let(:organisation) { build(:partner_organisation) }

      it { should be_valid }
    end

    context "when the organisation is the service owner" do
      let(:organisation) { build(:beis_organisation) }

      it { should be_invalid }
    end
  end

  context "when activity is a third party project" do
    subject { build(:third_party_project_activity, organisation: organisation) }

    context "when the organisation is a partner organisation" do
      let(:organisation) { build(:partner_organisation) }

      it { should be_valid }
    end

    context "when the organisation is the service owner" do
      let(:organisation) { build(:beis_organisation) }

      it { should be_invalid }
    end
  end
end
