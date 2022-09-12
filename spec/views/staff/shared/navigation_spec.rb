RSpec.describe "shared/_navigation" do
  let(:policy_stub) { double("policy") }

  before do
    without_partial_double_verification do
      allow(view).to receive(:policy) do |record|
        Pundit.policy(user, record)
      end
      allow(view).to receive(:current_user).and_return(user)
      allow(user).to receive(:organisation_id).and_return(SecureRandom.uuid)
    end

    render
  end

  context "when the current user is a BEIS user" do
    let(:user) { build(:beis_user) }

    it "shows the link to the exports index" do
      expect(rendered).to have_link(t("page_title.export.index"), href: exports_path)
    end

    it "does not show the link to an organisation export page" do
      expect(rendered).to_not have_link(t("page_title.export.index"), href: exports_organisation_path(id: user.organisation_id))
    end
  end

  context "when the current user is a partner organisation user" do
    let(:user) { build(:partner_organisation_user) }

    it "does not show the link to the exports index" do
      expect(rendered).to_not have_link(t("page_title.export.index"), href: exports_path)
    end

    it "shows the link to the partner organisation's organisation export page" do
      expect(rendered).to have_link(t("page_title.export.index"), href: exports_organisation_path(id: user.organisation_id))
    end
  end
end
