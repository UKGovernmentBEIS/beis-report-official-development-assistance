require "rails_helper"

RSpec.describe AnonymiseDeactivatedUsersJob, type: :job do
  describe "the job" do
    subject(:job) { AnonymiseDeactivatedUsersJob.perform_async }

    it "is enqueued" do
      expect { job }.to change(AnonymiseDeactivatedUsersJob.jobs, :size).by(1)
    end

    it "is drained" do
      job
      AnonymiseDeactivatedUsersJob.drain
      expect(AnonymiseDeactivatedUsersJob.jobs.size).to eq 0
    end
  end

  describe "#perform" do
    let(:the_recent_past) { 2.years.ago }
    let(:the_distant_past) { 6.years.ago }

    it "anonymises a user who has been inactive for more than 5 years" do
      create(:beis_user, deactivated_at: the_distant_past)

      described_class.new.perform

      expect(User.first.anonymised_at).not_to eq nil
    end

    it "does not anonymise a user who has been inactive for less than 5 years" do
      create(:beis_user, deactivated_at: the_recent_past)

      described_class.new.perform

      expect(User.first.anonymised_at).to eq nil
    end

    it "anonymises a set of users who were deactivated in the distant past" do
      5.times { create(:beis_user, deactivated_at: the_distant_past) }

      described_class.new.perform

      expect(User.deactivated.count).to eq 0
      expect(User.where.not(anonymised_at: nil).count).to eq 5
    end

    it "does not anonymise a set of users who were deactivated in the recent past" do
      5.times { create(:beis_user, deactivated_at: the_recent_past) }

      described_class.new.perform

      expect(User.deactivated.count).to eq 5
      expect(User.where.not(anonymised_at: nil).count).to eq 0
    end
  end
end
