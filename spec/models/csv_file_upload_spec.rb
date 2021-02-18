require "rails_helper"

RSpec.describe CsvFileUpload do
  let(:csv) do
    <<~CSV
      foo,bar,baz
      1,2,3
    CSV
  end
  let(:file) { double("File") }
  let(:params) do
    {
      csv: file,
    }
  end

  let(:upload) { described_class.new(params, :csv) }

  context "when the file is present" do
    before do
      allow(file).to receive(:read) { csv }
    end

    it "is valid" do
      expect(upload.valid?).to be true
    end

    it "returns the expected rows" do
      expect(upload.rows).to be_a(CSV::Table)
      expect(upload.rows.first.to_h).to eq({"foo" => "1", "bar" => "2", "baz" => "3"})
    end

    context "when the file has a BOM prefix" do
      let(:bom) { "\uFEFF" }
      let(:csv) do
        bom + <<~CSV
          foo,bar,baz
          1,2,hëllo
        CSV
      end

      it "is valid" do
        expect(upload.valid?).to be true
      end

      it "parses the CSV without the BOM" do
        expect(upload.rows).to be_a(CSV::Table)
        expect(upload.rows.first.to_h).to eq({"foo" => "1", "bar" => "2", "baz" => "hëllo"})
      end
    end

    context "when the file is invalid" do
      let(:csv) do
        <<~CSV
          foo,bar,baz
          \xA3201,\xA3202,\xA3203
        CSV
      end

      it "is invalid" do
        expect(upload.valid?).to be false
      end

      it "returns no rows" do
        expect(upload.rows).to be_nil
      end
    end
  end

  context "when there is no file" do
    let(:file) { nil }

    it "is invalid" do
      expect(upload.valid?).to be false
    end

    it "returns no rows" do
      expect(upload.rows).to be_nil
    end
  end
end
