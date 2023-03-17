RSpec.describe Activity::Import::Field do
  describe ".all" do
    subject { described_class.all }

    it "returns an array of all Field objects" do
      expect(subject.count).to eq 50
      expect(subject).to all(be_a(described_class))

      linked_activity_id_field = subject.find { |field| field.attribute_name == :linked_activity_id }
      expect(linked_activity_id_field).to be_nil
    end

    context "when the `activity_linking` feature flag is active" do
      before { allow(ROLLOUT).to receive(:active?).with(:activity_linking).and_return(true) }

      it "inlcudes linked_activity_id" do
        expect(subject.count).to eq 51
        expect(subject).to all(be_a(described_class))

        linked_activity_id_field = subject.find { |field| field.attribute_name == :linked_activity_id }
        expect(linked_activity_id_field).to be_present
      end
    end
  end

  describe ".find_by_attribute_name" do
    let(:attribute_name) { :roda_identifier }

    subject { described_class.find_by_attribute_name(attribute_name: attribute_name) }

    context "when the attribute does not exist" do
      let(:attribute_name) { :not_in_csv }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    it "returns an instance of Field" do
      expect(subject).to be_a(described_class)
      expect(subject).to have_attributes(attribute_name: attribute_name, heading: "RODA ID", exclude_from_converter: true)
    end
  end

  describe ".where_headings" do
    let(:headings) { ["RODA ID", "Parent RODA ID"] }

    subject { described_class.where_headings(headings: headings) }

    it "returns an array of Fields" do
      expected = [
        have_attributes(attribute_name: :roda_identifier, heading: "RODA ID", exclude_from_converter: true),
        have_attributes(attribute_name: :parent_id, heading: "Parent RODA ID", exclude_from_converter: true)
      ]

      expect(subject).to all(be_a(described_class))
      expect(subject).to match_array(expected)
    end
  end

  describe ".where_level_and_type" do
    let(:field_headings) { subject.map(&:heading) }

    subject { described_class.where_level_and_type(level: level, type: type) }

    context "Level B" do
      let(:level) { :level_b }

      context "ISPF ODA" do
        let(:type) { :ispf_oda }
        let(:expected_field_headings) do
          [
            "RODA ID",
            "Parent RODA ID",
            "Transparency identifier",
            "Title",
            "Description",
            "Benefitting Countries",
            "Partner organisation identifier",
            "GDI",
            "SDG 1",
            "SDG 2",
            "SDG 3",
            "ODA Eligibility",
            "Activity Status",
            "Planned start date",
            "Planned end date",
            "Actual start date",
            "Actual end date",
            "Sector",
            "Aid type",
            "Aims/Objectives",
            "ISPF themes",
            "ISPF ODA partner countries",
            "ISPF non-ODA partner countries",
            "Tags",
            "Original commitment figure",
            "Comments"
          ]
        end

        it "returns the expected fields" do
          expect(subject).to all(be_a(described_class))
          expect(field_headings).to eq expected_field_headings
        end

        context "when the `activity_linking` feature flag is active" do
          before { allow(ROLLOUT).to receive(:active?).with(:activity_linking).and_return(true) }

          it "includes linked activity" do
            expect(field_headings).to match_array expected_field_headings << "Linked activity RODA ID"
          end
        end
      end

      context "ISPF non-ODA" do
        let(:type) { :ispf_non_oda }
        let(:expected_field_headings) do
          [
            "RODA ID",
            "Parent RODA ID",
            "Title",
            "Description",
            "Partner organisation identifier",
            "Activity Status",
            "Planned start date",
            "Planned end date",
            "Actual start date",
            "Actual end date",
            "Sector",
            "ISPF themes",
            "ISPF non-ODA partner countries",
            "Tags",
            "Original commitment figure",
            "Comments"
          ]
        end

        it "returns the expected fields" do
          expect(subject).to all(be_a(described_class))
          expect(field_headings).to eq expected_field_headings
        end

        context "when the `activity_linking` feature flag is active" do
          before { allow(ROLLOUT).to receive(:active?).with(:activity_linking).and_return(true) }

          it "includes linked activity" do
            expect(field_headings).to match_array expected_field_headings << "Linked activity RODA ID"
          end
        end
      end

      context "non-ISPF" do
        let(:type) { :non_ispf }
        let(:expected_field_headings) do
          [
            "RODA ID",
            "Parent RODA ID",
            "Transparency identifier",
            "Title",
            "Description",
            "Benefitting Countries",
            "Partner organisation identifier",
            "GDI",
            "GCRF Strategic Area",
            "GCRF Challenge Area",
            "SDG 1",
            "SDG 2",
            "SDG 3",
            "Newton Fund Pillar",
            "Covid-19 related research",
            "ODA Eligibility",
            "Activity Status",
            "Planned start date",
            "Planned end date",
            "Actual start date",
            "Actual end date",
            "Sector",
            "Collaboration type (Bi/Multi Marker)",
            "Aid type",
            "Free Standing Technical Cooperation",
            "Aims/Objectives",
            "NF Partner Country PO",
            "Original commitment figure",
            "Comments"
          ]
        end

        it "returns the expected fields" do
          expect(field_headings).to eq expected_field_headings
          expect(subject).to all(be_a(described_class))
        end
      end
    end

    context "Level C/D" do
      let(:level) { :level_c_d }

      context "ISPF ODA" do
        let(:type) { :ispf_oda }
        let(:expected_field_headings) do
          [
            "RODA ID",
            "Parent RODA ID",
            "Transparency identifier",
            "Title",
            "Description",
            "Benefitting Countries",
            "Partner organisation identifier",
            "GDI",
            "SDG 1",
            "SDG 2",
            "SDG 3",
            "Covid-19 related research",
            "ODA Eligibility",
            "ODA Eligibility Lead",
            "Activity Status",
            "Call open date",
            "Call close date",
            "Total applications",
            "Total awards",
            "Planned start date",
            "Planned end date",
            "Actual start date",
            "Actual end date",
            "Sector",
            "Channel of delivery code",
            "Collaboration type (Bi/Multi Marker)",
            "DFID policy marker - Gender",
            "DFID policy marker - Climate Change - Adaptation",
            "DFID policy marker - Climate Change - Mitigation",
            "DFID policy marker - Biodiversity",
            "DFID policy marker - Desertification",
            "DFID policy marker - Disability",
            "DFID policy marker - Disaster Risk Reduction",
            "DFID policy marker - Nutrition",
            "Aid type",
            "Free Standing Technical Cooperation",
            "Aims/Objectives",
            "UK PO Named Contact",
            "ISPF themes",
            "ISPF ODA partner countries",
            "ISPF non-ODA partner countries",
            "Implementing organisation names",
            "Tags",
            "Original commitment figure",
            "Comments"
          ]
        end

        it "returns the expected fields" do
          expect(field_headings).to eq expected_field_headings
          expect(subject).to all(be_a(described_class))
        end

        context "when the `activity_linking` feature flag is active" do
          before { allow(ROLLOUT).to receive(:active?).with(:activity_linking).and_return(true) }

          it "includes linked activity" do
            expect(field_headings).to match_array expected_field_headings << "Linked activity RODA ID"
          end
        end
      end

      context "ISPF non-ODA" do
        let(:type) { :ispf_non_oda }
        let(:expected_field_headings) do
          [
            "RODA ID",
            "Parent RODA ID",
            "Title",
            "Description",
            "Partner organisation identifier",
            "Activity Status",
            "Call open date",
            "Call close date",
            "Total applications",
            "Total awards",
            "Planned start date",
            "Planned end date",
            "Actual start date",
            "Actual end date",
            "Sector",
            "UK PO Named Contact",
            "ISPF themes",
            "ISPF non-ODA partner countries",
            "Implementing organisation names",
            "Tags",
            "Original commitment figure",
            "Comments"
          ]
        end

        it "returns the expected fields" do
          expect(subject).to all(be_a(described_class))
          expect(field_headings).to eq expected_field_headings
        end

        context "when the `activity_linking` feature flag is active" do
          before { allow(ROLLOUT).to receive(:active?).with(:activity_linking).and_return(true) }

          it "includes linked activity" do
            expect(field_headings).to match_array expected_field_headings << "Linked activity RODA ID"
          end
        end
      end

      context "non-ISPF" do
        let(:type) { :non_ispf }
        let(:expected_field_headings) do
          [
            "RODA ID",
            "Parent RODA ID",
            "Transparency identifier",
            "Title",
            "Description",
            "Benefitting Countries",
            "Partner organisation identifier",
            "GDI",
            "GCRF Strategic Area",
            "GCRF Challenge Area",
            "SDG 1",
            "SDG 2",
            "SDG 3",
            "Newton Fund Pillar",
            "Covid-19 related research",
            "ODA Eligibility",
            "ODA Eligibility Lead",
            "Activity Status",
            "Call open date",
            "Call close date",
            "Total applications",
            "Total awards",
            "Planned start date",
            "Planned end date",
            "Actual start date",
            "Actual end date",
            "Sector",
            "Channel of delivery code",
            "Collaboration type (Bi/Multi Marker)",
            "DFID policy marker - Gender",
            "DFID policy marker - Climate Change - Adaptation",
            "DFID policy marker - Climate Change - Mitigation",
            "DFID policy marker - Biodiversity",
            "DFID policy marker - Desertification",
            "DFID policy marker - Disability",
            "DFID policy marker - Disaster Risk Reduction",
            "DFID policy marker - Nutrition",
            "Aid type",
            "Free Standing Technical Cooperation",
            "Aims/Objectives",
            "UK PO Named Contact",
            "NF Partner Country PO",
            "Implementing organisation names",
            "Original commitment figure",
            "Comments"
          ]
        end

        it "returns the expected fields" do
          expect(subject).to all(be_a(described_class))
          expect(field_headings).to eq expected_field_headings
        end
      end
    end
  end

  describe ".invalid_for_level_b_ispf_non_oda" do
    let(:expected_fields) do
      %i[
        transparency_identifier
        benefitting_countries
        gdi
        sdg_1
        sdg_2
        sdg_3
        oda_eligibility
        aid_type
        objectives
        ispf_oda_partner_countries
      ]
    end

    subject { described_class.invalid_for_level_b_ispf_non_oda }

    it "returns a list of fields which are invalid for level B ISPF non-ODA activities" do
      expect(subject).to eq expected_fields
    end
  end

  describe ".invalid_for_level_c_d_ispf_non_oda" do
    let(:expected_fields) do
      %i[
        transparency_identifier
        benefitting_countries
        gdi
        sdg_1
        sdg_2
        sdg_3
        covid19_related
        oda_eligibility
        oda_eligibility_lead
        channel_of_delivery_code
        collaboration_type
        policy_marker_gender
        policy_marker_climate_change_adaptation
        policy_marker_climate_change_mitigation
        policy_marker_biodiversity
        policy_marker_desertification
        policy_marker_disability
        policy_marker_disaster_risk_reduction
        policy_marker_nutrition
        aid_type
        fstc_applies
        objectives
        ispf_oda_partner_countries
      ]
    end

    subject { described_class.invalid_for_level_c_d_ispf_non_oda }

    it "returns a list of fields which are invalid for level C and D ISPF non-ODA activities" do
      expect(subject).to eq expected_fields
    end
  end
end
