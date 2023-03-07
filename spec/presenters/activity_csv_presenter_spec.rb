require "rails_helper"

RSpec.describe ActivityCsvPresenter do
  describe "#sector" do
    context "when there is a non-empty sector" do
      it "returns 'sector code: description'" do
        activity = build(:project_activity, sector: 11110)
        result = described_class.new(activity).sector
        expect(result).to eq("11110: Education policy and administrative management")
      end
    end
  end

  describe "#aid_type" do
    context "when there is a non-empty aid_type" do
      it "returns 'aid type code: description'" do
        activity = build(:project_activity, aid_type: "D02")
        result = described_class.new(activity).aid_type
        expect(result).to eq("D02: Other technical assistance")
      end
    end
  end

  describe "#flow" do
    let(:is_oda) { true }
    let(:activity) { build(:project_activity, is_oda: is_oda) }

    subject { described_class.new(activity).flow }

    context "when activity is non-ODA" do
      let(:is_oda) { false }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when there is a non-empty flow" do
      it "returns 'flow code: description'" do
        expect(subject).to eq("10: ODA")
      end
    end
  end

  describe "#finance" do
    let(:is_oda) { true }
    let(:activity) { build(:project_activity, is_oda: is_oda) }

    subject { described_class.new(activity).finance }

    context "when activity is non-ODA" do
      let(:is_oda) { false }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when there is a non-empty finance" do
      it "returns 'finance code: description'" do
        expect(subject).to eq("110: Standard grant")
      end
    end
  end

  describe "#tied_status" do
    let(:is_oda) { true }
    let(:activity) { build(:project_activity, is_oda: is_oda) }

    subject { described_class.new(activity).tied_status }

    context "when activity is non-ODA" do
      let(:is_oda) { false }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when there is a non-empty tied status" do
      it "returns 'tied status code: description'" do
        expect(subject).to eq("5: Untied")
      end
    end
  end

  describe "#benefitting_countries" do
    context "when there are benefitting countries" do
      it "returns the benefitting countries separated by semicolons" do
        activity = build(:project_activity, benefitting_countries: ["AR", "EC", "BR"])
        result = described_class.new(activity).benefitting_countries
        expect(result).to eq("Argentina; Ecuador; Brazil")
      end
    end

    context "when there is an unexpected country code" do
      it "handles the unexpected country code" do
        activity = build(:project_activity, benefitting_countries: ["UK"])
        result = described_class.new(activity).benefitting_countries
        expect(result).to eq(t("page_content.activity.unknown_country", code: "UK"))
      end
    end

    context "when there are no benefitting countries" do
      it "returns nil" do
        activity = build(:project_activity, benefitting_countries: nil)
        result = described_class.new(activity).benefitting_countries
        expect(result).to be_nil
      end
    end
  end

  describe "#intended_beneficiaries" do
    context "when there are other benefitting countries" do
      it "returns the benefitting countries separated by semicolons" do
        activity = build(:project_activity, intended_beneficiaries: ["AR", "EC", "BR"])
        result = described_class.new(activity).intended_beneficiaries
        expect(result).to eq("Argentina; Ecuador; Brazil")
      end
    end

    context "when there are no other benefitting countries" do
      it "returns nil" do
        activity = build(:project_activity, intended_beneficiaries: nil)
        result = described_class.new(activity).intended_beneficiaries
        expect(result).to be_nil
      end
    end
  end

  describe "#ispf_oda_partner_countries" do
    context "when there are ISPF ODA partner countries" do
      it "returns the ISPF ODA partner countries separated by semicolons" do
        activity = build(:project_activity, ispf_oda_partner_countries: ["BR", "EG"])
        result = described_class.new(activity).ispf_oda_partner_countries
        expect(result).to eq("Brazil; Egypt")
      end
    end

    context "when there are no ISPF ODA partner countries" do
      it "returns nil" do
        activity = build(:project_activity, ispf_oda_partner_countries: nil)
        result = described_class.new(activity).ispf_oda_partner_countries
        expect(result).to be_nil
      end
    end
  end

  describe "#ispf_non_oda_partner_countries" do
    context "when there are ISPF non-ODA partner countries" do
      it "returns the ISPF non-ODA partner countries separated by semicolons" do
        activity = build(:project_activity, ispf_non_oda_partner_countries: ["CA", "IN"])
        result = described_class.new(activity).ispf_non_oda_partner_countries
        expect(result).to eq("Canada; India (non-ODA)")
      end
    end

    context "when there are no ISPF non-ODA partner countries" do
      it "returns nil" do
        activity = build(:project_activity, ispf_non_oda_partner_countries: nil)
        result = described_class.new(activity).ispf_non_oda_partner_countries
        expect(result).to be_nil
      end
    end
  end

  describe "#beis_identifier" do
    it "returns an empty string if the BEIS ID is nil otherwise the value" do
      activity = Activity.new(beis_identifier: nil)
      result = described_class.new(activity).beis_identifier

      expect(result).to eq ""

      fake_beis_identifier = "GCRF_AHRC_NS_AH1001"
      activity.beis_identifier = fake_beis_identifier
      result = described_class.new(activity).beis_identifier

      expect(result).to eq fake_beis_identifier
    end
  end

  describe "#country_partner_organisations" do
    context "when there are more than one country partner organisations" do
      it "returns them separated by pipes" do
        activity = build(:programme_activity, country_partner_organisations: ["National Council for the State Funding Agencies (CONFAP)",
          "Chinese Academy of Sciences",
          "National Research Foundation"])
        result = described_class.new(activity).country_partner_organisations
        expect(result).to eq("National Council for the State Funding Agencies (CONFAP)|Chinese Academy of Sciences|National Research Foundation")
      end
    end

    context "when there are no country partner organisations" do
      it "returns nil" do
        activity = build(:programme_activity, country_partner_organisations: nil)
        result = described_class.new(activity).country_partner_organisations
        expect(result).to be_nil
      end
    end
  end

  describe "#implementing_organisations" do
    it "is blank when there are no implementing organisations" do
      activity = build(:project_activity)
      result = described_class.new(activity).implementing_organisations

      expect(result).to be_nil
    end

    it "shows a list of implementing organisations separated by the pipe symbol" do
      implementing_organisation_one = build(:implementing_organisation)
      implementing_organisation_two = build(:implementing_organisation)
      activity = create(:project_activity)
      activity.implementing_organisations = [implementing_organisation_one, implementing_organisation_two]
      result = described_class.new(activity).implementing_organisations

      expect(result).to eq("#{implementing_organisation_one.name}|#{implementing_organisation_two.name}")
    end
  end

  describe "#fstc_applies" do
    let(:fstc_applies) { true }
    let(:is_oda) { nil }
    let(:activity) { build(:project_activity, fstc_applies: fstc_applies, is_oda: is_oda) }

    subject { described_class.new(activity).fstc_applies }

    context "when super is nil and activity is non-ODA" do
      let(:fstc_applies) { nil }
      let(:is_oda) { false }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when fstc_applies is true" do
      let(:fstc_applies) { true }

      it "returns yes" do
        expect(subject).to eq "yes"
      end
    end

    context "when fstc_applies is false" do
      let(:fstc_applies) { false }

      it "returns no" do
        expect(subject).to eq "no"
      end
    end
  end

  describe "#is_oda" do
    context "when the activity is ODA" do
      let(:activity) { build(:project_activity, is_oda: true) }

      it "returns ODA" do
        expect(described_class.new(activity).is_oda).to eq "ODA"
      end
    end

    context "when the activity is non-ODA" do
      let(:activity) { build(:project_activity, is_oda: false) }

      it "returns non-ODA" do
        expect(described_class.new(activity).is_oda).to eq "Non-ODA"
      end
    end
  end

  describe "#linked_activity_identifier" do
    context "when the activity is not ISPF-funded" do
      it "returns nil" do
        activity = build(:programme_activity, :gcrf_funded)

        expect(described_class.new(activity).linked_activity_identifier).to be_nil
      end
    end

    context "when there's no linked activity" do
      it "returns nil" do
        activity = build(:programme_activity, :ispf_funded, linked_activity: nil)

        expect(described_class.new(activity).linked_activity_identifier).to be_nil
      end
    end

    context "when there is a linked activity" do
      it "returns the linked activity's RODA identifier" do
        linked_non_oda_activity = build(:programme_activity, :ispf_funded, is_oda: false, roda_identifier: "ISPF-NON-ODA-ID")
        activity = build(:programme_activity, :ispf_funded, is_oda: true, linked_activity: linked_non_oda_activity)

        expect(described_class.new(activity).linked_activity_identifier).to eq("ISPF-NON-ODA-ID")
      end
    end
  end

  describe "#parent_programme_identifier" do
    let(:programme) { build(:programme_activity, roda_identifier: "lvl-b") }
    let(:project) { build(:project_activity, parent: programme, roda_identifier: "lvl-c") }

    context "when the activity is a third_party_project" do
      it "returns the RODA ID of the programme to which this third_party_project ultimately belongs" do
        activity = build(:third_party_project_activity, parent: project)
        result = described_class.new(activity).parent_programme_identifier
        expect(result).to eq("lvl-b")
      end
    end

    context "when the activity is a project" do
      it "returns the RODA ID of the programme to which this project belongs" do
        result = described_class.new(project).parent_programme_identifier
        expect(result).to eq("lvl-b")
      end
    end

    context "when the activity is a programme" do
      it "returns nil" do
        result = described_class.new(programme).parent_programme_identifier
        expect(result).to be_nil
      end
    end

    context "when the activity is a fund" do
      it "returns nil" do
        result = described_class.new(programme.parent).parent_programme_identifier
        expect(result).to be_nil
      end
    end
  end

  describe "#parent_programme_title" do
    let(:programme) { build(:programme_activity, title: "Level B activity") }
    let(:project) { build(:project_activity, parent: programme, title: "Level C activity") }

    context "when the activity is a third_party_project" do
      it "returns the title of the programme to which this third_party_project ultimately belongs" do
        activity = build(:third_party_project_activity, parent: project)
        result = described_class.new(activity).parent_programme_title
        expect(result).to eq("Level B activity")
      end
    end

    context "when the activity is a project" do
      it "returns the title of the programme to which this project belongs" do
        result = described_class.new(project).parent_programme_title
        expect(result).to eq("Level B activity")
      end
    end

    context "when the activity is a programme" do
      it "returns nil" do
        result = described_class.new(programme).parent_programme_title
        expect(result).to be_nil
      end
    end

    context "when the activity is a fund" do
      it "returns nil" do
        result = described_class.new(programme.parent).parent_programme_title
        expect(result).to be_nil
      end
    end
  end

  describe "#parent_project_identifier" do
    let(:programme) { build(:programme_activity, roda_identifier: "lvl-b") }
    let(:project) { build(:project_activity, parent: programme, roda_identifier: "lvl-c") }

    context "when the activity is a third_party_project" do
      it "returns the RODA ID of the project to which this third_party_project belongs" do
        activity = build(:third_party_project_activity, parent: project)
        result = described_class.new(activity).parent_project_identifier
        expect(result).to eq("lvl-c")
      end
    end

    context "when the activity is a project" do
      it "returns nil" do
        result = described_class.new(project).parent_project_identifier
        expect(result).to be_nil
      end
    end

    context "when the activity is a programme" do
      it "returns nil" do
        result = described_class.new(programme).parent_project_identifier
        expect(result).to be_nil
      end
    end

    context "when the activity is a fund" do
      it "returns nil" do
        result = described_class.new(programme.parent).parent_project_identifier
        expect(result).to be_nil
      end
    end
  end

  describe "#parent_project_title" do
    let(:programme) { build(:programme_activity, title: "Level B activity") }
    let(:project) { build(:project_activity, parent: programme, title: "Level C activity") }

    context "when the activity is a third_party_project" do
      it "returns the title of the project to which this third_party_project ultimately belongs" do
        activity = build(:third_party_project_activity, parent: project)
        result = described_class.new(activity).parent_project_title
        expect(result).to eq("Level C activity")
      end
    end

    context "when the activity is a project" do
      it "returns nil" do
        result = described_class.new(project).parent_project_title
        expect(result).to be_nil
      end
    end

    context "when the activity is a programme" do
      it "returns nil" do
        result = described_class.new(programme).parent_project_title
        expect(result).to be_nil
      end
    end

    context "when the activity is a fund" do
      it "returns nil" do
        result = described_class.new(programme.parent).parent_project_title
        expect(result).to be_nil
      end
    end
  end

  describe "#ispf_themes" do
    it "returns ISPF themes separated by pipe characters" do
      activity = build(:project_activity, ispf_themes: [1, 2, 3])
      result = described_class.new(activity).ispf_themes
      expect(result).to eq("Net zero|Resilient planet|Tomorrow's technologies")
    end
  end
end
