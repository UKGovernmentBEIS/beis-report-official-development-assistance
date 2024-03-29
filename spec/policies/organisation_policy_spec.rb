require "rails_helper"

RSpec.describe OrganisationPolicy do
  subject { described_class.new(user, organisation) }

  let(:organisation) { create(:partner_organisation) }

  context "as user that belongs to BEIS" do
    let(:user) { build_stubbed(:beis_user) }

    it "permits all actions" do
      is_expected.to permit_action(:index)
      is_expected.to permit_action(:show)
      is_expected.to permit_action(:bulk_upload)
      is_expected.to permit_new_and_create_actions
      is_expected.to permit_edit_and_update_actions
      is_expected.to permit_action(:destroy)
      is_expected.to permit_action(:download)
    end
  end

  context "as user that does NOT belong to BEIS" do
    context "when the user belongs to that organisation" do
      let(:user) { build_stubbed(:partner_organisation_user, organisation: organisation) }

      it "controls actions as expected" do
        is_expected.to permit_action(:index)
        is_expected.to permit_action(:show)
        is_expected.to forbid_action(:bulk_upload)
        is_expected.to forbid_new_and_create_actions
        is_expected.to permit_edit_and_update_actions
        is_expected.to forbid_action(:destroy)
        is_expected.to forbid_action(:download)
      end
    end

    context "when the user does NOT belong to that organisation" do
      let(:user) { build_stubbed(:partner_organisation_user, organisation: create(:partner_organisation)) }

      it "only permits index" do
        is_expected.to permit_action(:index)
        is_expected.to forbid_action(:show)
        is_expected.to forbid_action(:bulk_upload)
        is_expected.to forbid_new_and_create_actions
        is_expected.to forbid_edit_and_update_actions
        is_expected.to forbid_action(:destroy)
        is_expected.to forbid_action(:download)
      end

      context "when the organisation is an implementing organisation" do
        let(:organisation) { create(:implementing_organisation) }

        it "only permits index" do
          is_expected.to permit_action(:index)
          is_expected.to forbid_action(:show)
          is_expected.to forbid_action(:bulk_upload)
          is_expected.to forbid_new_and_create_actions
          is_expected.to forbid_edit_and_update_actions
          is_expected.to forbid_action(:destroy)
          is_expected.to forbid_action(:download)
        end
      end
    end
  end
end
