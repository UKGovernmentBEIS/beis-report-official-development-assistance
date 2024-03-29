require "rails_helper"

RSpec.describe "the custom error pages" do
  it "responds with a custom 404 page" do
    get "/404"

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include t("page_title.errors.not_found")
  end

  it "responds with a custom 500 page" do
    get "/500"

    expect(response).to have_http_status(:internal_server_error)
    expect(response.body).to include t("page_title.errors.internal_server_error")
  end

  it "responds with a custom 422 page" do
    get "/422"

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include t("page_title.errors.unacceptable")
  end
end
