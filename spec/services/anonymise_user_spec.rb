require "rails_helper"

RSpec.describe AnonymiseUser do
  let(:user) { create(:inactive_user) }
  let(:active_user) { create(:administrator) }

  describe "#call" do
    it "returns a successful result" do
      result = AnonymiseUser.new(user:).call

      expect(result).to be_success
      expect(result).not_to be_failure
    end

    it "cannot anonymise an active user" do
      expect { AnonymiseUser.new(user: active_user).call }.to raise_error("Active users cannot be anonymised")
    end

    it "anonymises the email address" do
      email = user.email
      AnonymiseUser.new(user:).call
      expect(user.email).not_to eql(email)

      # Domain element of email address should be unchanged:
      expect(user.email.split("@").last).to eql(email.split("@").last)
    end

    it "anonymises the name" do
      name = user.name
      AnonymiseUser.new(user:).call
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
