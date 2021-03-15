require "rails_helper"

RSpec.describe SendWelcomeEmail do
  let(:user) { create(:administrator) }

  describe "#call" do
    it "enqueues the welcome email to be sent" do
      expect {
        described_class.new(user: user).call
      }.to have_enqueued_mail(UserMailer, :welcome).with(args: [user])
    end
  end
end
