require "rails_helper"

RSpec.describe AnonymiseUser do
  let(:user) { create(:administrator) }

  describe "#call" do
    it "returns a successful result" do
      result = described_class.new(user: user).call

      expect(result.success?).to be(true)
      expect(result.failure?).to be(false)
    end

    it "anonymises the email address" do
      email = user.email
      described_class.new(user:).call
      expect(user.email).not_to eql(email)

      # Domain element of email address should be unchanged:
      expect(user.email.split("@").last).to eql(email.split("@").last)
    end

    it "anonymises the name" do
      name = user.name
      described_class.new(user:).call
      expect(user.name).not_to eql(name)

      # Check IDs match; they're in this format:
      #  "Deleted User <id>", "deleted.user.<id>@<domain>"
      expect(user.name.split(" ").last).to eql(user.email.split("@").first.split(".").last)
    end

    it "removes the mobile number" do
      described_class.new(user:).call
      expect(user.mobile_number).to be_blank
    end
  end
end
