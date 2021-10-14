RSpec.describe "rake commitments:import", type: :task do
  let(:user) { create(:beis_user) }

  it "returns an error if the CSV is blank" do
    ClimateControl.modify USER_EMAIL: user.email do
      expect { task.execute }.to raise_error(SystemExit, /You must specify a CSV/)
    end
  end

  it "returns an error if the USER_EMAIL is blank" do
    ClimateControl.modify CSV: "/path/to/a/fil" do
      expect { task.execute }.to raise_error(SystemExit, /You must specify a USER_EMAIL/)
    end
  end

  it "returns an error if the CSV cannot be found" do
    ClimateControl.modify CSV: "/foo/bar/baz", USER_EMAIL: user.email do
      expect {
        task.execute
      }.to raise_error(SystemExit, "Cannot find the file at /foo/bar/baz")
    end
  end

  it "returns an error if the user cannot be found" do
    ClimateControl.modify CSV: "/foo/bar/baz", USER_EMAIL: "not and emai" do
      expect {
        task.execute
      }.to raise_error(SystemExit, "Unknown user email address")
    end
  end

  context "with the correct environment variables" do
    context "When there are no errors from the importer" do
      let(:importer) do
      end

      it "outputs the number of activities imported and updated" do
        commitments = create_list(:commitment, 2)

        importer = double(:importer, errors: [], imported: commitments)

        allow(importer).to receive(:call).and_return(true)
        allow(CSV).to receive(:read)
        allow(Import::Commitments).to receive(:new) { importer }

        ClimateControl.modify CSV: "/foo/bar/baz", USER_EMAIL: user.email do
          expect { task.execute }.to output(
            /commitment_id: #{commitments.first.id} | activity_id: #{commitments.first.activity_id} | value: #{commitments.first.value}/
          ).to_stdout
          expect { task.execute }.to output(/2 commitments imported successfully/).to_stdout
        end
      end
    end

    context "When there are errors from the importer" do
      it "outputs the specific errors" do
        errors = [
          Import::Commitments::RowError.new("Value must be greater than 0", 1),
          Import::Commitments::RowError.new("Value must be greater than 0", 2),
        ]

        importer = double(:importer, errors: errors, imported: [])

        allow(importer).to receive(:call).and_return(false)
        allow(CSV).to receive(:read)
        allow(Import::Commitments).to receive(:new) { importer }

        ClimateControl.modify CSV: "/foo/bar/baz", USER_EMAIL: user.email do
          expect { task.execute }.to output(/Row 1: Value must be greater than 0/).to_stdout
          expect { task.execute }.to output(/There were errors, no commitments were imported./).to_stdout
        end
      end
    end
  end
end
