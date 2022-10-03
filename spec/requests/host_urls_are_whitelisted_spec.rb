require "rails_helper"

RSpec.describe "host urls are checked against a whitelist", type: :request do
  scenario "a whitelisted host is accepted and an OK response is received" do
    get root_path, headers: {"Host" => "test.local"}
    expect(response).to have_http_status("200")
  end

  scenario "a bad host is rejected and the request is forbidden" do
    get root_path, headers: {"Host" => "baddomain.com"}
    expect(response).to have_http_status("403")
  end
end
