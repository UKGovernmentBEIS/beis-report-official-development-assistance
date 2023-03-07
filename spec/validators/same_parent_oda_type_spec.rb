require "rails_helper"

RSpec.describe SameParentOdaTypeValidator do
  let(:ispf) { Fund.by_short_name("ISPF") }

  let(:oda_programme_activity) {
    build(
      :programme_activity,
      :ispf_funded,
      is_oda: true
    )
  }

  let(:non_oda_programme_activity) {
    build(
      :programme_activity,
      :ispf_funded,
      is_oda: false
    )
  }

  let(:non_oda_project_activity) {
    build(
      :project_activity,
      :ispf_funded,
      is_oda: false
    )
  }

  context "when creating an ODA activity on an ODA parent" do
    subject {
      build(
        :project_activity,
        :ispf_funded,
        is_oda: true,
        parent: oda_programme_activity
      )
    }
    it { should be_valid }
  end

  context "when creating a non-ODA activity on a non-ODA parent" do
    subject {
      build(
        :project_activity,
        :ispf_funded,
        is_oda: false,
        parent: non_oda_programme_activity
      )
    }
    it { should be_valid }
  end

  context "when the activity's parent is a fund" do
    subject { oda_programme_activity }

    it { should be_valid }
  end

  context "when the activity is not ISPF" do
    subject { build(:project_activity, :gcrf_funded) }

    it { should be_valid }
  end

  context "when creating a non-ODA activity on an ODA parent" do
    subject {
      build(
        :project_activity,
        :ispf_funded,
        is_oda: false,
        parent: oda_programme_activity
      )
    }
    it { should be_invalid }
  end

  context "when creating an ODA activity on a non-ODA parent" do
    subject {
      build(
        :project_activity,
        :ispf_funded,
        is_oda: true,
        parent: non_oda_programme_activity
      )
    }
    it { should be_invalid }
  end
end
