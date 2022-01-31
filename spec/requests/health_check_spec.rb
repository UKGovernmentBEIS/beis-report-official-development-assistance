require "rails_helper"
require "sidekiq/api"

RSpec.describe "Health Check", type: :request do
  it "returns an ok HTTP status code without requiring authentication" do
    ClimateControl.modify CURRENT_SHA: "b9c73f88", TIME_OF_BUILD: "2020-01-01T00:00:00Z" do
      get "/health_check", headers: {"CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json"}
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eql(
        "rails" => "OK",
        "git_sha" => "b9c73f88",
        "built_at" => "2020-01-01T00:00:00Z",
        "sidekiq" => {
          "enqueued" => 0,
          "retry_size" => 0
        }
      )
    end
  end

  context "when enqueued is 20" do
    it "returns the correct size" do
      stats_double = double(Sidekiq::Stats, enqueued: 20, retry_size: 0)
      allow(Sidekiq::Stats).to receive(:new).and_return(stats_double)

      get "/health_check", headers: {"CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json"}

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("sidekiq", "enqueued")).to eql(20)
    end
  end

  context "when retry_size is 20" do
    it "returns the correct size" do
      stats_double = double(Sidekiq::Stats, retry_size: 20, enqueued: 0)
      allow(Sidekiq::Stats).to receive(:new).and_return(stats_double)

      get "/health_check", headers: {"CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json"}

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("sidekiq", "retry_size")).to eql(20)
    end
  end
end
