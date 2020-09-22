require "rails_helper"

RSpec.describe IngestCsvRow do
  describe "#call" do
    it "takes an attribute hash, processes each key and returns a new hash" do
      input = {
        "call_open_date" => "28/04/2019",
        "call_close_date" => "28/04/2021",
      }

      output = IngestCsvRow.new(input).call

      expect(output).to include(
        "call_open_date" => Date.new(2019, 4, 28),
        "call_close_date" => Date.new(2021, 4, 28),
        "call_present" => true,
      )
    end

    it "strips whitespace from string values" do
      input = {
        "dummy_value_1" => "   value",
        "dummy_value_2" => "value  ",
      }

      output = IngestCsvRow.new(input).call

      expect(output).to include(
        "dummy_value_1" => "value",
        "dummy_value_2" => "value",
      )
    end

    context "setting call_present" do
      it "is set to true if call_open_date is provided" do
        input = {
          "call_open_date" => "25/12/2020",
        }

        output = IngestCsvRow.new(input).call

        expect(output).to include(
          "call_present" => true
        )
      end

      it "is set to true if call_open_close is provided" do
        input = {
          "call_close_date" => "25/12/2020",
        }

        output = IngestCsvRow.new(input).call

        expect(output).to include(
          "call_present" => true
        )
      end

      it "is set to false if both call_open_date or call_close_date are empty" do
        input = {
          "call_open_date" => " ",
          "call_close_date" => "",
        }

        output = IngestCsvRow.new(input).call

        expect(output).to include(
          "call_present" => false,
          "call_open_date" => :skip,
          "call_close_date" => :skip
        )
      end

      it "isn't set if call_open_date and call_close_date not included in attributes" do
        input = {}

        output = IngestCsvRow.new(input).call

        expect(output).not_to include("call_open_date", "call_close_date", "call_present")
      end
    end
  end

  context "#process_call_open_date" do
    it "returns the parsed date" do
      expect(IngestCsvRow.new.process_call_open_date("25/12/2020"))
        .to eql Date.new(2020, 12, 25)
    end

    it "returns :skip for a blank value" do
      expect(IngestCsvRow.new.process_call_open_date(nil)).to eql :skip
    end

    it "returns :skip when value is N/A" do
      expect(IngestCsvRow.new.process_call_open_date("N/A")).to eql :skip
    end

    it "returns :skip when value is 'not applicable'" do
      expect(IngestCsvRow.new.process_call_open_date("NOT APPLICABLE")).to eql :skip
    end
  end

  context "#process_call_close_date" do
    it "returns the parsed date" do
      expect(IngestCsvRow.new.process_call_close_date("2020-12-25"))
        .to eql Date.new(2020, 12, 25)
    end

    it "returns :skip for a blank value" do
      expect(IngestCsvRow.new.process_call_close_date(nil)).to eql :skip
    end

    it "returns :skip when value is N/A" do
      expect(IngestCsvRow.new.process_call_close_date("N/A")).to eql :skip
    end

    it "returns :skip when value is 'not applicable'" do
      expect(IngestCsvRow.new.process_call_close_date("not applicable")).to eql :skip
    end
  end

  context "#process_programme_status" do
    it "maps the textual programme status to its equivalent status code" do
      expect(IngestCsvRow.new.process_programme_status("Delivery"))
        .to eql "01"
    end

    it "sets the status attribute to the IATI-equivalent status" do
      input = {"programme_status" => "Delivery"}
      output = IngestCsvRow.new(input).call

      expect(output).to include(
        "status" => "2"
      )
    end
  end

  context "#process_oda_eligibility" do
    it "returns true when the value is 'eligible'" do
      expect(IngestCsvRow.new.process_oda_eligibility("ELIgibLE"))
        .to be(true)
    end

    it "returns false when the value is not 'eligible'" do
      expect(IngestCsvRow.new.process_oda_eligibility("something-else"))
        .to be(false)
    end

    it "returns false when the value is nil" do
      expect(IngestCsvRow.new.process_oda_eligibility(nil))
        .to be(false)
    end
  end

  context "#process_gdi" do
    it "returns the mapped gdi code" do
      expect(IngestCsvRow.new.process_gdi("NO"))
        .to eql "4"
    end

    it "returns nil when the value is 'not applicable'" do
      expect(IngestCsvRow.new.process_gdi("Not Applicable"))
        .to be_nil
    end

    it "returns nil when the value is 'na'" do
      expect(IngestCsvRow.new.process_gdi("NA"))
        .to be_nil
    end

    it "skips for other values" do
      expect(IngestCsvRow.new.process_gdi("xxxx"))
        .to eql :skip
    end
  end

  context "#process_total_applications" do
    it "returns non-zero values untouched" do
      expect(IngestCsvRow.new.process_total_applications("1234"))
        .to eql "1234"
    end

    it "returns empty values as zero" do
      expect(IngestCsvRow.new.process_total_applications(""))
        .to eql "0"
    end

    it "returns zero when value is 'Not Applicable'" do
      expect(IngestCsvRow.new.process_total_applications("NOT APPLICABLE"))
        .to eql "0"
    end
  end

  context "#process_total_awards" do
    it "returns non-zero values untouched" do
      expect(IngestCsvRow.new.process_total_awards("5678"))
        .to eql "5678"
    end

    it "returns empty values as zero" do
      expect(IngestCsvRow.new.process_total_awards(""))
        .to eql "0"
    end

    it "returns zero when value is 'Not Applicable'" do
      expect(IngestCsvRow.new.process_total_awards("not applicable"))
        .to eql "0"
    end
  end

  context "#process_intended_beneficiaries" do
    it "returns an array of country codes" do
      expect(IngestCsvRow.new.process_intended_beneficiaries("Peru|Zambia"))
        .to include("PE", "ZM")
    end

    it "still returns an array if one of the countries is unknown" do
      expect(IngestCsvRow.new.process_intended_beneficiaries("Peru|Scarfolk|Zambia"))
        .to include("PE", "ZM")
    end

    it "handles incorrectly-named Laos correctly" do
      expect(IngestCsvRow.new.process_intended_beneficiaries("Laos"))
        .to include("LA")
    end

    it "handles incorrectly-named St Lucia correctly" do
      expect(IngestCsvRow.new.process_intended_beneficiaries("St Lucia"))
        .to include("LC")
    end

    it "returns an empty array if value is empty" do
      expect(IngestCsvRow.new.process_intended_beneficiaries("  "))
        .to eql []
    end

    it "returns an empty array if value is 'None'" do
      expect(IngestCsvRow.new.process_intended_beneficiaries("none"))
        .to eql []
    end

    it "returns an empty array if value is 'Not applicable'" do
      expect(IngestCsvRow.new.process_intended_beneficiaries("not applicable"))
        .to eql []
    end

    it "returns an empty array if delimitered list is empty" do
      expect(IngestCsvRow.new.process_intended_beneficiaries(" |  "))
        .to eql []
    end
  end

  context "#process_sector" do
    it "returns the mapped sector code" do
      expect(IngestCsvRow.new.process_sector("medical research"))
        .to eql "12182"
    end

    it "sets the sector_category attribute to a value suitable for this sector" do
      input = {"sector" => "Medical Research"}
      output = IngestCsvRow.new(input).call

      expect(output).to include(
        "sector_category" => "121"
      )
    end

    it "is skipped when value cannot be mapped" do
      expect(IngestCsvRow.new.process_sector("wrong sector"))
        .to eql :skip
    end
  end

  context "#process_recipient_country" do
    context "when the value is a known country" do
      it "returns the mapped country code" do
        expect(IngestCsvRow.new.process_recipient_country("Algeria"))
          .to eql "DZ"
      end

      it "sets the geography attribute to recipient_country" do
        input = {"recipient_country" => "Algeria"}
        output = IngestCsvRow.new(input).call

        expect(output).to include(
          "geography" => "recipient_country"
        )
      end

      it "sets the recipient_region to the region that the recipient_country is in" do
        input = {"recipient_country" => "Algeria"}
        output = IngestCsvRow.new(input).call

        expect(output).to include(
          "recipient_region" => "189"
        )
      end
    end

    context "when the value is a known region" do
      it "return nil, as recipient_country shouldn't be set in this case" do
        expect(IngestCsvRow.new.process_recipient_country("Far East Asia, regional"))
          .to be_nil
      end

      it "sets the geography attribute to recipient_region" do
        input = {"recipient_country" => "Far East Asia, regional"}
        output = IngestCsvRow.new(input).call

        expect(output).to include(
          "geography" => "recipient_region"
        )
      end

      it "sets the recipient_region attribute to the mapped region code" do
        input = {"recipient_country" => "Far East Asia, regional"}
        output = IngestCsvRow.new(input).call

        expect(output).to include(
          "recipient_region" => "789"
        )
      end
    end

    it "skips when the country or region cannot be found" do
      expect(IngestCsvRow.new.process_recipient_country("Non-existent"))
        .to eql :skip
    end
  end

  context "#process_flow" do
    it "returns the mapped sector code" do
      expect(IngestCsvRow.new.process_flow("ODA"))
        .to eql "10"
    end

    it "is skipped when value cannot be mapped" do
      expect(IngestCsvRow.new.process_flow("bad-flow"))
        .to eql :skip
    end

    it "is skipped when value is blank" do
      expect(IngestCsvRow.new.process_flow(""))
        .to eql :skip
    end

    it "is skipped when value is 'not applicable'" do
      expect(IngestCsvRow.new.process_flow("NOT APPLICABLE"))
        .to eql :skip
    end
  end

  context "#process_planned_start_date" do
    it "returns the parsed date" do
      expect(IngestCsvRow.new.process_planned_start_date("25/12/2020"))
        .to eql Date.new(2020, 12, 25)
    end

    it "returns :skip for a blank value" do
      expect(IngestCsvRow.new.process_planned_start_date(""))
        .to eql :skip
    end

    it "returns :skip when value is N/A" do
      expect(IngestCsvRow.new.process_planned_start_date("N/A"))
        .to eql :skip
    end

    it "returns :skip when value is 'not applicable'" do
      expect(IngestCsvRow.new.process_planned_start_date("NOT APPLICABLE"))
        .to eql :skip
    end
  end

  context "#process_planned_end_date" do
    it "returns the parsed date" do
      expect(IngestCsvRow.new.process_planned_end_date("25/12/2020"))
        .to eql Date.new(2020, 12, 25)
    end
  end

  context "#process_actual_start_date" do
    it "returns the parsed date" do
      expect(IngestCsvRow.new.process_actual_start_date("25/12/2020"))
        .to eql Date.new(2020, 12, 25)
    end
  end

  context "#process_actual_end_date" do
    it "returns the parsed date" do
      expect(IngestCsvRow.new.process_actual_end_date("25/12/2020"))
        .to eql Date.new(2020, 12, 25)
    end
  end

  context "#process_aid_type" do
    it "returns the mapped aid type code" do
      expect(IngestCsvRow.new.process_aid_type("other technical assistance"))
        .to eql "D02"
    end

    it "is skipped when value cannot be mapped" do
      expect(IngestCsvRow.new.process_aid_type("bad-aid-type"))
        .to eql :skip
    end

    it "is skipped when value is blank" do
      expect(IngestCsvRow.new.process_aid_type(""))
        .to eql :skip
    end

    it "is skipped when value is 'not applicable'" do
      expect(IngestCsvRow.new.process_aid_type("NOT APPLICABLE"))
        .to eql :skip
    end
  end
end
