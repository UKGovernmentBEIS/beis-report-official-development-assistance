require "rails_helper"

RSpec.describe "Canonical domain redirect", type: :request do
  before(:all) do
    @original_hostname = ENV["CANONICAL_HOSTNAME"]
    ENV["CANONICAL_HOSTNAME"] = "http://beis-roda.com"
    Rails.application.reload_routes!
  end

  after(:all) do
    ENV["CANONICAL_HOSTNAME"] = @original_domain
    Rails.application.reload_routes!
  end

  it "redirects to the canonical domain" do
    expect(get("http://test.local/")).to redirect_to("http://beis-roda.com/")
    expect(response.status).to eq(301)
  end

  it "keeps the original path" do
    expect(get("http://test.local/pages/cookie_statement")).to redirect_to("http://beis-roda.com/pages/cookie_statement")
    expect(response.status).to eq(301)
  end

  it "keeps query strings in place" do
    expect(get("http://test.local/pages/cookie_statement?foo=bar")).to redirect_to("http://beis-roda.com/pages/cookie_statement?foo=bar")
    expect(response.status).to eq(301)
  end
end
