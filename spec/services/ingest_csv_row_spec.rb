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

      it "is set to false if neither call_open_date or call_close_date is provided" do
        input = {}

        output = IngestCsvRow.new(input).call

        expect(output).to include(
          "call_present" => false
        )
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

    it "returns an empty array if value is empty" do
      expect(IngestCsvRow.new.process_intended_beneficiaries("  "))
        .to eql []
    end

    it "returns an empty array if delimitered list is empty" do
      expect(IngestCsvRow.new.process_intended_beneficiaries(" |  "))
        .to eql []
    end
  end
end
