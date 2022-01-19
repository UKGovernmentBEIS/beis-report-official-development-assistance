require "rails_helper"
require "auth0"

RSpec.describe CreateUserInAuth0 do
  describe "#call" do
    let(:user) { create(:administrator) }

    subject { described_class.new(user: user).call }

    before(:each) do
      stub_auth0_token_request
    end

    it "creates the user in Auth0 and updates the local user auth_id" do
      auth0_create_call = stub_auth0_create_user_request(
        email: user.email,
        auth0_identifier: "auth0|555ffff"
      )

      subject

      expect(auth0_create_call).to have_been_requested
      expect(user.identifier).to eq("auth0|555ffff")
    end

    context "when an error is thrown" do
      context "for an unexpected reason" do
        it "raises the error as an unhandled exception" do
          params = JSON[{
            "statusCode" => 500,
            "error" => "Foo",
            "message" => "Bar",
            "errorCode" => "x_error"
          }]

          unexpected_error = Auth0::Unsupported.new(params)

          allow_any_instance_of(Auth0Api).to receive_message_chain(:client, :create_user)
            .and_raise(unexpected_error)

          expect { subject }.to raise_error(unexpected_error)
        end
      end
    end
  end

  describe "#temporary_password" do
    it "conforms to the Auth0 criteria" do
      password = described_class.temporary_password

      expect(password).to match(/[a-z]/)
      expect(password).to match(/[A-Z]/)
      expect(password).to match(/[0-9]/)
      expect(password).to match(/[!@#$%^&*]/)
    end
  end
end
