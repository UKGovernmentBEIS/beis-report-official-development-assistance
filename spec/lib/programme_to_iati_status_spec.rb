require "rails_helper"

RSpec.describe "#programme_status_to_iati_status" do
  context "when the user sets the programme status for an activity" do
    it "sets the correct IATI status automatically" do
      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("01")
      expect(status).to eq "2"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("02")
      expect(status).to eq "1"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("03")
      expect(status).to eq "1"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("04")
      expect(status).to eq "1"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("05")
      expect(status).to eq "1"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("06")
      expect(status).to eq "1"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("07")
      expect(status).to eq "2"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("08")
      expect(status).to eq "3"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("09")
      expect(status).to eq "4"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("10")
      expect(status).to eq "5"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("11")
      expect(status).to eq "5"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("12")
      expect(status).to eq "6"
    end
  end
end
