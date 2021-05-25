class Public::BaseController < ApplicationController
  def health_check
    render json: {
      rails: "OK",
      git_sha: ENV.fetch("CURRENT_SHA", nil),
      built_at: ENV.fetch("TIME_OF_BUILD", nil),
    }, status: :ok
  end
end
