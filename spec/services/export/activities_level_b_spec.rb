require "rails_helper"

RSpec.describe Export::ActivitiesLevelB do
  let(:export) { Export::ActivitiesLevelB.new(fund:) }

  before do
    Fund.all.each { |fund| create(:fund_activity, source_fund_code: fund.id, roda_identifier: fund.short_name) }
  end

  describe "#headers" do
    subject(:headers) { export.headers }

    context "fund is ISPF" do
      let(:fund) { Fund.by_short_name("ISPF") }

      it "has ISPF-only columns" do
        expect(headers).to include("ODA or Non-ODA")
        expect(headers).to include("ISPF ODA partner countries")
        expect(headers).to include("ISPF themes")
        expect(headers).to include("Tags")
      end
    end
    context "fund is GCRF" do
      let(:fund) { Fund.by_short_name("GCRF") }

      it "has no ISPF-only columns" do
        expect(headers).not_to include("ODA or Non-ODA")
        expect(headers).not_to include("ISPF ODA partner countries")
        expect(headers).not_to include("ISPF themes")
        expect(headers).not_to include("Tags")
      end

      it "has GCRF-only columns" do
        expect(headers).to include("GCRF Strategic Area")
        expect(headers).to include("GCRF Challenge Area")
      end
    end
    context "fund is Newton" do
      let(:fund) { Fund.by_short_name("NF") }

      it "has no ISPF-only columns" do
        expect(headers).not_to include("ODA or Non-ODA")
        expect(headers).not_to include("ISPF ODA partner countries")
        expect(headers).not_to include("ISPF themes")
        expect(headers).not_to include("Tags")
      end

      it "has NF-only columns" do
        expect(headers).to include("Newton Fund Country Partner Organisations")
        expect(headers).to include("Newton Fund Pillar")
      end
    end
  end

  describe "#rows" do
    subject(:rows) { export.rows }
    let(:first_row) { export.headers.zip(export.rows.first).to_h } # express the first row as a hash of k/v
    let(:common_expected_values) do
      {
        "Partner Organisation" => programme_activity.extending_organisation.name,
        "Activity level" => "Programme (level B)",
        "Partner organisation identifier" => a_string_starting_with("GCRF-"),
        "RODA identifier" => a_string_starting_with("#{fund.short_name}-"),
        "IATI identifier" => a_string_starting_with("GB-GOV-26-"),
        "Linked activity" => nil,
        "Activity title" => programme_activity.title,
        "Activity description" => programme_activity.description,
        "Aims or objectives" => programme_activity.objectives,
        "Sector" => "11110: Education policy and administrative management",
        "Original commitment figure" => "£250,000.00",
        "Activity status" => "Spend in progress",
        "Planned start date" => "31 Jan 2025",
        "Planned end date" => "1 Feb 2025",
        "Actual start date" => "30 Jan 2025",
        "Actual end date" => "31 Jan 2025",
        "Benefitting countries" => "Argentina; Ecuador; Brazil",
        "Benefitting region" => "South America, regional",
        "Global Development Impact" => "GDI not applicable",
        "Sustainable Development Goals" => "Not applicable",
        "Aid type" => "D01: Donor country personnel",
        "ODA eligibility" => "Eligible",
        "Publish to IATI?" => "Yes"
      }
    end

    before { travel_to Date.new(2025, 1, 31) } # Factories default to dates around today for actual/planned dates

    context "fund is ISPF" do
      let(:fund) { Fund.by_short_name("ISPF") }
      let!(:programme_activity) do
        create(
          :programme_activity, :ispf_funded, commitment: create(:commitment, value: BigDecimal("250_000.00")),
          benefitting_countries: %w[AR EC BR], tags: [4, 5], transparency_identifier: "GB-GOV-26-1234-5678-91011"
        )
      end

      it "has a row with ISPF-specific and common values" do
        expect(first_row).to match a_hash_including(
          {
            "Parent activity" => "International Science Partnerships Fund",
            "ODA or Non-ODA" => "ODA",
            "ISPF ODA partner countries" => "India (ODA)",
            "ISPF non-ODA partner countries" => "India (non-ODA)",
            "ISPF themes" => "Resilient Planet",
            "Tags" => "Tactical Fund|Previously reported under OODA"
          }.reverse_merge(common_expected_values)
        )
      end
    end

    context "fund is GCRF" do
      let(:fund) { Fund.by_short_name("GCRF") }
      let!(:programme_activity) do
        create(
          :programme_activity, :gcrf_funded, commitment: create(:commitment, value: BigDecimal("250_000.00")),
          benefitting_countries: %w[AR EC BR], transparency_identifier: "GB-GOV-26-1234-5678-91011"
        )
      end

      it "has a row with GCRF-specific and common values" do
        expect(first_row).to match a_hash_including(
          {
            "Parent activity" => "Global Challenges Research Fund",
            "GCRF Strategic Area" => "UKRI Collective Fund (2017 allocation) and Academies Collective Fund: Resilient Futures",
            "GCRF Challenge Area" => "Not applicable"
          }.reverse_merge(common_expected_values)
        )
      end
    end

    context "fund is OODA" do
      let(:fund) { Fund.by_short_name("OODA") }
      let!(:programme_activity) do
        create(
          :programme_activity, :ooda_funded, commitment: create(:commitment, value: BigDecimal("250_000.00")),
          benefitting_countries: %w[AR EC BR], transparency_identifier: "GB-GOV-26-1234-5678-91011"
        )
      end

      it "has a row with OODA-specific and common values" do
        expect(first_row).to match a_hash_including(
          {
            "Parent activity" => "Other ODA"
          }.reverse_merge(common_expected_values)
        )
      end
    end

    context "fund is Newton" do
      let(:fund) { Fund.by_short_name("NF") }
      let!(:programme_activity) do
        create(
          :programme_activity, :newton_funded, commitment: create(:commitment, value: BigDecimal("250_000.00")),
          benefitting_countries: %w[AR EC BR], transparency_identifier: "GB-GOV-26-1234-5678-91011",
          country_partner_organisations: ["National Council for the State Funding Agencies (CONFAP)", "Other"],
          fund_pillar: "1" # People
        )
      end

      it "has a row with Newton-specific and common values" do
        expect(first_row).to match a_hash_including(
          {
            "Parent activity" => "Newton Fund",
            "Newton Fund Country Partner Organisations" => "National Council for the State Funding Agencies (CONFAP)|Other",
            "Newton Fund Pillar" => "People"
          }.reverse_merge(common_expected_values)
        )
      end
    end
  end
end
