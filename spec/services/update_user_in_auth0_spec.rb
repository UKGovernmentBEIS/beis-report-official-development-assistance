require "rails_helper"
require "auth0"

RSpec.describe UpdateUserInAuth0 do
  describe "#call" do
    let(:user) { create(:user, identifier: "auth0|555ffff") }

    subject { described_class.new(user: user) }

    before(:each) do
      stub_auth0_token_request
    end

    it "updates the user in Auth0" do
      auth0_update_call = stub_auth0_update_user_request(
        auth0_identifier: "auth0|555ffff",
        email: "new@example.com",
        name: "New Name",
      )

      subject.call

      expect(auth0_update_call).to have_been_requested
    end

    context "when an error is thrown" do
      context "for an unexpected reason" do
        it "raises the error as an unhandled exception" do
          params = JSON[{
            "statusCode" => 500,
            "error" => "Foo",
            "message" => "Bar",
            "errorCode" => "x_error",
          }]

          unexpected_error = Auth0::Unsupported.new(params)

          allow_any_instance_of(Auth0Api).to receive_message_chain(:client, :update_user)
            .and_raise(unexpected_error)

          expect { subject.call }.to raise_error(unexpected_error)
        end
      end
    end
  end
end
