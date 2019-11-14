class Public::BaseController < ApplicationController
  def health_check
    render json: {rails: "OK"}, status: :ok
  end
end
