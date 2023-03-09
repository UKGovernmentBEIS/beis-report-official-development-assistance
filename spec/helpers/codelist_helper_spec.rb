require "rails_helper"

RSpec.describe CodelistHelper, type: :helper do
  describe "version 2_03" do
    let(:version) { "2_03" }

    describe "#region_name_from_code" do
      it "returns the name of the region from a code number" do
        expect(helper.region_name_from_code("998")).to eq("Developing countries, unspecified")
      end
    end

    describe "#country_name_from_code" do
      it "returns the name of the country from a code number" do
        expect(helper.country_name_from_code("DZ")).to eq("Algeria")
      end
    end

    describe "#collaboration_type_radio_options" do
      it "returns the different options for collaboration type sorted by code" do
        options = helper.collaboration_type_radio_options

        expect(options.length).to eq 3
        expect(options.first.code).to eq "1"
        expect(options.first.name).to eq "Bilateral"
        expect(options.last.code).to eq "3"
        expect(options.last.name).to eq "Bilateral, core contributions to NGOs and other private bodies / PPPs"
      end
    end

    describe "#sector_radio_options" do
      it "returns all sectors when no category is passed" do
        options = helper.sector_radio_options

        expect(options.length).to eq 295
        expect(options).to include OpenStruct.new(name: "15170: Women's rights organisations and movements, and government institutions", code: "15170", category: "151")
        expect(options).to include OpenStruct.new(name: "60010: Action relating to debt", code: "60010", category: "600")
      end

      it "returns only the sectors from the category when one is passed" do
        options = helper.sector_radio_options(category: 112)

        expect(options.length).to eq 7
        expect(options).to include OpenStruct.new(name: "11231: Basic life skills for youth", code: "11231", category: "112")
        expect(options).to include OpenStruct.new(name: "11250: School feeding", code: "11250", category: "112")
        expect(options).not_to include OpenStruct.new(name: "73010: Immediate post-emergency reconstruction and rehabilitation", code: "73010", category: "730")
      end
    end

    describe "#aid_type_radio_options" do
      it "returns the aid type with the code appended to the name" do
        options = helper.aid_type_radio_options

        expect(options.length).to eq 8
        expect(options.first.name).to eq "B02: Core contributions to multilateral institutions"
        expect(options.last.name).to eq "G01: Administrative costs not included elsewhere"
      end
    end

    describe "#policy_markers_radio_options" do
      it "returns the options for policy markers with not assessed at the first option" do
        options = helper.policy_markers_radio_options

        expect(options.length).to eq 4
        expect(options.first.label).to eq("Not assessed")
        expect(options.first.value).to eq("not_assessed")
        expect(options.last.label).to eq("Principal objective")
        expect(options.last.value).to eq("principal_objective")
      end
    end

    describe "#policy_markers_desertification_radio_options" do
      it "returns the options for policy markers with not assessed at the first option" do
        options = helper.policy_markers_desertification_radio_options

        expect(options.length).to eq 5
        expect(options.first.label).to eq("Not assessed")
        expect(options.first.value).to eq("not_assessed")
        expect(options.last.label).to eq("Principal objective AND in support of an action programme")
        expect(options.last.value).to eq("principal_objective_and_in_support_of_an_action_programme")
      end
    end
  end

  describe "BEIS" do
    describe "#oda_eligibility_radio_options" do
      it "returns the radio options and hints for ODA eligibility" do
        options = helper.oda_eligibility_radio_options

        expect(options.length).to eq 3
        expect(options.first.label).to eq("No - was never eligible")
        expect(options.first.description).to eq("The activity was reported as eligible but was actually never ODA eligible, this applies to past and future spend")
        expect(options.last.label).to eq("No longer eligible")
        expect(options.last.description).to eq("The activity used to be ODA eligible but no longer meets the OECD DAC rules for future spend")
      end
    end

    describe "#programme_status_radio_options" do
      it "returns the BEIS codes and descriptions" do
        options = helper.programme_status_radio_options

        expect(options.length).to eq 12
        expect(options.first.value).to eq "delivery"
        expect(options.first.label).to eq "Delivery"
        expect(options.first.description).to eq "Activities related to delivery costs"
        expect(options.last.value).to eq "paused"
        expect(options.last.label).to eq "Paused"
        expect(options.last.description).to eq "Activity has been temporarily suspended. No spend should take place while this status is in use"
      end
    end

    describe "#iati_status_from_programme_status" do
      it "returns the IATI status corresponding to the BEIS programme status" do
        %w[planned agreement_in_place open_for_applications review decided].each do |ps|
          expect(helper.iati_status_from_programme_status(ps)).to eql "1"
        end

        %w[delivery spend_in_progress].each do |ps|
          expect(helper.iati_status_from_programme_status(ps)).to eql "2"
        end

        ps = "finalisation"
        expect(helper.iati_status_from_programme_status(ps)).to eql "3"

        ps = "completed"
        expect(helper.iati_status_from_programme_status(ps)).to eql "4"

        %w[stopped cancelled].each do |ps|
          expect(helper.iati_status_from_programme_status(ps)).to eql "5"
        end

        ps = "paused"
        expect(helper.iati_status_from_programme_status(ps)).to eql "6"
      end
    end

    describe "#covid19_related_radio_options" do
      it "returns the BEIS codes and descriptions" do
        options = helper.covid19_related_radio_options

        expect(options.length).to eq 5
        expect(options.first.code).to eq 0
        expect(options.first.description).to eq "Not related"
        expect(options.last.code).to eq 4
        expect(options.last.description).to eq "Existing activity adapted to somewhat focus on COVID-19"
      end
    end

    describe "#gcrf_challenge_area_options" do
      it "returns the BEIS codes and descriptions" do
        options = helper.gcrf_challenge_area_options

        expect(options.length).to eq 13
        expect(options.first.code).to eq 0
        expect(options.first.description).to eq "Not applicable"
        expect(options.last.code).to eq 12
        expect(options.last.description).to eq "Reduce poverty and inequality, including gender inequalities"
      end
    end

    describe "#fund_pillar_radio_options" do
      it "returns the BEIS codes and descriptions" do
        options = helper.fund_pillar_radio_options

        expect(options.length).to eq 4
        expect(options.first.code).to eq 0
        expect(options.first.description).to eq "Not Applicable"
        expect(options.last.code).to eq 3
        expect(options.last.description).to eq "Translation"
      end
    end

    describe "#ispf_themes_options" do
      it "returns the BEIS codes and descriptions" do
        options = helper.ispf_themes_options

        expect(options.length).to eq 4
        expect(options.first.code).to eq 1
        expect(options.first.description).to eq "Resilient Planet"
        expect(options.last.code).to eq 4
        expect(options.last.description).to eq "Tomorrow's Talent"
      end
    end

    describe "#ispf_partner_countries_options" do
      context "when ODA" do
        it "returns the ODA partner country details in a hash" do
          options = helper.ispf_partner_countries_options(oda: true)

          expect(options.length).to eq(14)
          expect(options.first.code).to eq("BR")
          expect(options.first.name).to eq("Brazil")
          expect(options.last.code).to eq("NONE")
          expect(options.last.name).to eq("None (exemption agreed)")
        end
      end

      context "when non-ODA" do
        it "returns the non-ODA partner country details in a hash" do
          options = helper.ispf_partner_countries_options(oda: false)

          expect(options.length).to eq(12)
          expect(options.first.code).to eq("CA")
          expect(options.first.name).to eq("Canada")
          expect(options.last.code).to eq("NONE")
          expect(options.last.name).to eq("None (exemption agreed)")
        end

        context "when excluding 'none'" do
          it "returns all except 'none'" do
            options = helper.ispf_partner_countries_options(oda: false, allow_none: false)

            expect(options.length).to eq(11)
            expect(options.last.code).to eq("US")
            expect(options.last.name).to eq("USA")
          end
        end
      end
    end

    describe "#channel_of_delivery_codes" do
      it "returns the list of items whose codes are allowed by BEIS" do
        expect(helper.channel_of_delivery_codes.size).to eql 32
      end

      it "returns items with their IATI code and name" do
        first_item = helper.channel_of_delivery_codes.first

        expect(first_item.code).to eql "11000"
        expect(first_item.name).to eql "11000: Donor Government"
      end

      it "returns a restricted list for activities with Bilateral collaboration_type" do
        project = create(:project_activity, collaboration_type: "3")
        expect(helper.channel_of_delivery_codes(project).map(&:code)).to eq ["20000", "51000"]
      end
    end

    describe "#tags_options" do
      it "returns the BEIS codes and descriptions" do
        options = helper.tags_options

        expect(options.length).to eq 6
        expect(options.first.code).to eq 1
        expect(options.first.description).to eq "Ayrton Fund"
        expect(options.last.code).to eq 6
        expect(options.last.description).to eq "Previously reported under GCRF"
      end
    end
  end
end
