require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }

    it "should not allow an email to be changed" do
      user = create(:administrator, email: "old@example.com")

      user.email = "new@example.com"

      expect(user).to be_invalid
      expect(user.errors[:email]).to eq([I18n.t("activerecord.errors.models.user.attributes.email.cannot_be_changed")])
    end

    it "should allow an email to be changed if the user is anonymised" do
      user = create(:administrator, email: "old@example.com")

      user.anonymised_at = DateTime.now
      user.email = "new@example.com"

      expect(user).to be_valid
    end

    it "is not case sensitive" do
      # When a non-lowercase email address exists (Devise lowercases emails on creation so this is for pre-existing addresses)
      user = create(:partner_organisation_user)
      user.update_column(:email, "ForenameMacSurname@ClanMacSurname.org")
      expect(user.email).to eql("ForenameMacSurname@ClanMacSurname.org")

      # And Devise automatically lowercases the address on editing
      user.email = "forenamemacsurname@clanmacsurname.org"

      expect(user).to be_valid
    end

    it "won't allow a user to have its primary organisation also as an additional organisation" do
      user = create(:administrator)
      org = user.organisation
      user.organisation = org
      user.additional_organisations << org
      expect(user).to be_invalid
    end
  end

  describe "associations" do
    # This also validates that the relationship is present
    it { is_expected.to belong_to(:organisation) }
    it { is_expected.to have_many(:historical_events) }
    it { is_expected.to have_and_belong_to_many(:additional_organisations) }

    it "has a primary organisation" do
      user = create(:administrator)

      expect(user.primary_organisation).to be_valid
      expect(user.primary_organisation.id).to eq(user.organisation_id)
    end

    it "has additional organisations" do
      org1 = create(:partner_organisation)
      org2 = create(:partner_organisation)
      org3 = create(:partner_organisation)

      user = create(:administrator)
      user.additional_organisations << [org1, org2, org3]

      expect(user.additional_organisations.pluck(:id)).to include(org1.id)
      expect(user.additional_organisations.count).to eq(3)
    end

    it "shows all organisations including the primary organisation" do
      org = create(:partner_organisation)

      user = create(:administrator)
      user.additional_organisations << org

      expect(user.all_organisations.size).to eq(2)
      expect(user.all_organisations.pluck(:id)).to include(user.primary_organisation.id)
      expect(user.all_organisations.pluck(:id)).to include(org.id)
    end

    it "determines whether there are additional organisations" do
      org = create(:partner_organisation)

      user = create(:administrator)
      user.additional_organisations << org

      expect(user.additional_organisations?).to eq(true)

      user.additional_organisations = []
      expect(user.additional_organisations?).to eq(false)
    end

    context "when the current organisation has been set" do
      let(:current_organisation) do
        create(:partner_organisation)
      end

      before do
        Current.user_organisation = current_organisation.id
      end

      it "returns the current organisation instead of the primary organisation" do
        user = create(:administrator)

        expect(user.organisation).to eq(current_organisation)
        expect(user.current_organisation_id).to eq(current_organisation.id)
        expect(user.primary_organisation).not_to eq(current_organisation)
      end

      after do
        Current.user_organisation = nil
      end
    end

    context "when the current organisation has not been set" do
      it "returns the primary organisation" do
        user = create(:administrator)
        expect(user.current_organisation_id).to eq(user.organisation.id)
      end
    end
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:service_owner?).to(:organisation) }
    it { is_expected.to delegate_method(:partner_organisation?).to(:organisation) }
  end

  describe "scopes" do
    describe "#active" do
      it "shows only active users for active scope" do
        active_user = create(:partner_organisation_user, deactivated_at: nil)
        deactivated_user = create(:partner_organisation_user, deactivated_at: DateTime.yesterday)

        scoped_users = User.active

        expect(scoped_users).to include active_user
        expect(scoped_users).not_to include deactivated_user
      end
    end

    describe "#deactivated" do
      it "shows only deactivated users" do
        active_user = create(:partner_organisation_user, deactivated_at: nil)
        deactivated_user = create(:partner_organisation_user, deactivated_at: DateTime.yesterday)

        scoped_users = User.deactivated

        expect(scoped_users).to include deactivated_user
        expect(scoped_users).not_to include active_user
      end
    end

    describe "#index_active" do
      it "shows only active users sorted by the organisation and then name" do
        first_organisation = create(:partner_organisation, name: "A Organisation")
        last_organisation = create(:partner_organisation, name: "B Organisation")

        create(:partner_organisation_user, name: "A User", organisation: last_organisation)
        create(:partner_organisation_user, name: "B User", organisation: last_organisation)
        create(:partner_organisation_user, name: "Z User", organisation: first_organisation)

        scoped_users = User.all_active

        expect(scoped_users.first.name).to eql "Z User"
        expect(scoped_users.second.name).to eql "A User"
        expect(scoped_users.third.name).to eql "B User"
      end
    end

    describe "#index_deactivated" do
      it "shows only deactivated users sorted by the deactivated at time, then organisation and then name" do
        first_organisation = create(:partner_organisation, name: "A Organisation")
        last_organisation = create(:partner_organisation, name: "B Organisation")

        travel_to(DateTime.now) do
          create(:partner_organisation_user, name: "A User", deactivated_at: DateTime.yesterday)
          create(:partner_organisation_user, name: "B User", deactivated_at: DateTime.now - 1.week)
          create(:partner_organisation_user, name: "C User", organisation: last_organisation, deactivated_at: DateTime.now - 1.year)
          create(:partner_organisation_user, name: "D User", organisation: first_organisation, deactivated_at: DateTime.now - 1.year)
          create(:partner_organisation_user, name: "Z User", deactivated_at: DateTime.now - 2.year)
        end

        scoped_users = User.all_deactivated

        expect(scoped_users.first.name).to eql "Z User"
        expect(scoped_users.second.name).to eql "D User"
        expect(scoped_users.third.name).to eql "C User"
        expect(scoped_users.fourth.name).to eql "B User"
        expect(scoped_users.last.name).to eql "A User"
      end
    end
  end

  it "validates the email format" do
    user = build(:administrator, email: "bogus")

    expect(user).to be_invalid
    expect(user.errors[:email]).to eq(["is not a valid email"])
  end

  describe "password requirements" do
    it "should have a minimum length" do
      user = build(:administrator, password: "Ab3$")

      expect(user.valid?).to be_falsey
      expect(user.errors.messages[:password]).to include("Password is too short (minimum is 15 characters)")
    end

    it "should contain the required characters" do
      user = build(:administrator, password: "AaBbCc123456789")

      expect(user.valid?).to be_falsey
      expect(user.errors.messages[:password]).to include("Password must contain at least one punctuation mark or symbol")

      user.password = "AaBbCc123456789!"

      expect(user.valid?).to be_truthy
    end
  end

  describe "#active" do
    it "is aliased as active?" do
      user = build(:partner_organisation_user)

      expect(user.active?).to be true
    end

    context "when the user has no deactivated date" do
      it "is active" do
        user = build(:partner_organisation_user, deactivated_at: nil)

        expect(user.active?).to be true
      end
    end

    context "when the user has a deactivated date" do
      it "is not active" do
        user = build(:partner_organisation_user, deactivated_at: DateTime.yesterday)

        expect(user.active?).to be false
      end
    end
  end
end
