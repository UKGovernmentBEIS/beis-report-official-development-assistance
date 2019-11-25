require "rails_helper"

RSpec.describe SendWelcomeEmail do
  let(:user) { build_stubbed(:user) }
  before(:each) do
    stub_welcome_email_delivery
  end

  describe "#call" do
    it "enqueues the welcome email to be sent" do
      expect_welcome_email_delivery(user: user)
      described_class.new(user: user).call
    end
  end
end
