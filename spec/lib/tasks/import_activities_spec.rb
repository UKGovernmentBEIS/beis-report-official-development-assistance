require "rails_helper"

RSpec.describe "rake activities:import", type: :task do
  let(:organisation) { create(:organisation) }

  it "returns an error if the organisation is blank" do
    ClimateControl.modify CSV: "/foo/bar/baz" do
      expect {
        task.execute
      }.to raise_error(SystemExit, /You must specify an organisation ID/)
    end
  end

  it "returns an error if the CSV is blank" do
    ClimateControl.modify ORGANISATION_ID: organisation.id do
      expect {
        task.execute
      }.to raise_error(SystemExit, /You must specify a CSV/)
    end
  end

  it "returns an error if the CSV cannot be found" do
    ClimateControl.modify ORGANISATION_ID: organisation.id, CSV: "/foo/bar/baz" do
      expect {
        task.execute
      }.to raise_error(SystemExit, "Cannot find the file at /foo/bar/baz")
    end
  end

  it "returns an error if the organisation cannot be found" do
    ClimateControl.modify ORGANISATION_ID: "124", CSV: "/foo/bar/baz" do
      expect {
        task.execute
      }.to raise_error(SystemExit, "Can't find an organisation with the ID '124'")
    end
  end

  context "with the correct environment variables" do
    let(:csv) do
      <<~CSV
        foo,bar,baz
        1,2,3
      CSV
    end

    before do
      allow(File).to receive(:open).and_return(StringIO.new(csv))
      allow(Activities::ImportFromCsv).to receive(:new).with(organisation: organisation) { importer }
      allow(importer).to receive(:import).with(CSV.parse(csv, headers: true))
    end

    context "When there are no errors from the importer" do
      let(:importer) do
        double(:importer, errors: [], created: build_list(:activity, 3), updated: build_list(:activity, 2))
      end

      it "outputs the number of activities imported and updated" do
        ClimateControl.modify ORGANISATION_ID: organisation.id, CSV: "/foo/bar/baz" do
          expect { task.execute }.to output(/Successfully created 3 activities and updated 2 activities/).to_stdout
        end
      end
    end

    context "When there are errors from the importer" do
      let(:errors) do
        [
          Activities::ImportFromCsv::Error.new(1, :title, "Foo", "Blah"),
          Activities::ImportFromCsv::Error.new(2, :description, "Bar", "Blah"),
        ]
      end

      let(:importer) do
        double(:importer, errors: errors, created: [], updated: [])
      end

      it "outputs the number of errors" do
        ClimateControl.modify ORGANISATION_ID: organisation.id, CSV: "/foo/bar/baz" do
          expect { task.execute }.to output(/There were 2 errors when importing/).to_stdout
        end
      end

      it "outputs the specific errors" do
        ClimateControl.modify ORGANISATION_ID: organisation.id, CSV: "/foo/bar/baz" do
          expect { task.execute }.to output(/At row 3, column `Title`: Blah\nAt row 4, column `Description`: Blah/).to_stdout
        end
      end
    end
  end
end
