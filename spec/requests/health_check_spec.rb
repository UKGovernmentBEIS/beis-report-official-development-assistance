require "rails_helper"

RSpec.describe "Health Check", type: :request do
  it "returns an ok HTTP status code without requiring authentication" do
    ClimateControl.modify CURRENT_SHA: "b9c73f88", TIME_OF_BUILD: "2020-01-01T00:00:00Z" do
      get "/health_check", headers: {"CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json"}
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eql(
        "rails" => "OK",
        "git_sha" => "b9c73f88",
        "built_at" => "2020-01-01T00:00:00Z",
      )
    end
  end
end
