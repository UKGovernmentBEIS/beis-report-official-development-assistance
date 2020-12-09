require "rails_helper"

RSpec.describe "#programme_status_to_iati_status" do
  context "when the user sets the programme status for an activity" do
    it "sets the correct IATI status automatically" do
      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("delivery")
      expect(status).to eq "2"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("planned")
      expect(status).to eq "1"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("agreement_in_place")
      expect(status).to eq "1"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("open_for_applications")
      expect(status).to eq "1"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("review")
      expect(status).to eq "1"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("decided")
      expect(status).to eq "1"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("spend_in_progress")
      expect(status).to eq "2"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("finalisation")
      expect(status).to eq "3"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("completed")
      expect(status).to eq "4"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("stopped")
      expect(status).to eq "5"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("cancelled")
      expect(status).to eq "5"

      status = ProgrammeToIatiStatus.new.programme_status_to_iati_status("paused")
      expect(status).to eq "6"
    end
  end
end
