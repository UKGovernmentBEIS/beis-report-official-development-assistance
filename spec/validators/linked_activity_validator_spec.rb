require "rails_helper"

RSpec.describe LinkedActivityValidator do
  let(:extending_organisation) { create(:partner_organisation) }
  let(:gcrf) { Fund.by_short_name("GCRF") }
  let(:error_translations) { I18n.t("activerecord.errors.models.activity.attributes.linked_activity_id") }

  let(:oda_programme_activity) {
    create(
      :programme_activity,
      :ispf_funded,
      is_oda: true,
      extending_organisation: extending_organisation
    )
  }

  let(:second_oda_programme_activity) {
    create(
      :programme_activity,
      :ispf_funded,
      is_oda: true,
      extending_organisation: extending_organisation
    )
  }

  let(:non_oda_programme_activity) {
    create(
      :programme_activity,
      :ispf_funded,
      is_oda: false,
      extending_organisation: extending_organisation
    )
  }

  subject { oda_programme_activity }

  context "when valid" do
    it "should be valid" do
      subject.linked_activity = non_oda_programme_activity

      expect(subject).to be_valid
    end
  end

  context "when the linked activity is nil" do
    it { should be_valid }
  end

  context "when trying to relink to the existing linked activity" do
    it "should be valid" do
      subject.linked_activity = non_oda_programme_activity
      subject.save
      subject.linked_activity = non_oda_programme_activity

      expect(subject).to be_valid
    end
  end

  context "when the activity is a fund" do
    subject { create(:fund_activity, :ispf) }

    let(:other_fund) { create(:fund_activity) }

    it "should be invalid" do
      subject.linked_activity = other_fund

      expect(subject).to be_invalid
      expect(subject.errors[:linked_activity_id].first).to eq(error_translations[:fund])
    end
  end

  context "when trying to link to an activity of a different level" do
    let(:non_oda_project_activity) {
      create(
        :project_activity,
        :ispf_funded,
        is_oda: false,
        extending_organisation: extending_organisation
      )
    }

    it "should be invalid" do
      subject.linked_activity = non_oda_project_activity

      expect(subject).to be_invalid
      expect(subject.errors[:linked_activity_id].first).to eq(error_translations[:different_level])
    end
  end

  context "when the activity is not ISPF-funded" do
    it "should be invalid" do
      subject.source_fund = gcrf
      subject.linked_activity = non_oda_programme_activity

      expect(subject).to be_invalid
      expect(subject.errors[:linked_activity_id].first).to eq(error_translations[:incorrect_fund])
    end
  end

  context "when trying to link to an activity that is not ISPF-funded" do
    let(:gcrf_programme_activity) {
      create(
        :programme_activity,
        :gcrf_funded,
        extending_organisation: extending_organisation
      )
    }

    it "should be invalid" do
      subject.linked_activity = gcrf_programme_activity

      expect(subject).to be_invalid
      expect(subject.errors[:linked_activity_id].first).to eq(error_translations[:incorrect_fund])
    end
  end

  context "when trying to link to an activity of the same ODA type" do
    it "should be invalid" do
      subject.linked_activity = second_oda_programme_activity

      expect(subject).to be_invalid
      expect(subject.errors[:linked_activity_id].first).to eq(error_translations[:same_oda_type])
    end
  end

  context "when trying to link to an activity that is already linked to another" do
    before do
      non_oda_programme_activity.linked_activity = second_oda_programme_activity
      non_oda_programme_activity.save
      subject.linked_activity = non_oda_programme_activity
    end

    it "should be invalid" do
      expect(subject).to be_invalid
      expect(subject.errors[:linked_activity_id].first).to eq(error_translations[:proposed_linked_has_other_link])
    end
  end

  context "when trying to link to an activity with a different extending organisation" do
    let(:non_oda_programme_activity) {
      create(
        :programme_activity,
        :ispf_funded,
        is_oda: false,
        extending_organisation: create(:partner_organisation)
      )
    }

    it "should be invalid" do
      subject.linked_activity = non_oda_programme_activity

      expect(subject).to be_invalid
      expect(subject.errors[:linked_activity_id].first).to eq(error_translations[:different_extending_organisation])
    end
  end

  context "when trying to relink an activity with linked child activities" do
    it "should be invalid" do
      allow(subject).to receive(:linked_child_activities).and_return([double(:child_activity)])
      subject.linked_activity = non_oda_programme_activity

      expect(subject).to be_invalid
      expect(subject.errors[:linked_activity_id].first).to eq(error_translations[:linked_child_activities])
    end
  end

  context "when the parents of the activity and proposed linked activity are not linked" do
    let(:non_oda_project_activity) {
      create(
        :project_activity,
        :ispf_funded,
        is_oda: false,
        extending_organisation: extending_organisation
      )
    }

    subject {
      create(:project_activity,
        :ispf_funded,
        is_oda: true,
        extending_organisation: extending_organisation,
        linked_activity: nil)
    }

    it "should be invalid" do
      subject.linked_activity = non_oda_project_activity

      expect(subject).to be_invalid
      expect(subject.errors[:linked_activity_id].first).to eq(error_translations[:unlinked_parents])
    end
  end
end
