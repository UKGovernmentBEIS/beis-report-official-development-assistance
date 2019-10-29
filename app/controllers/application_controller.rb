# frozen_string_literal: true

class ApplicationController < ActionController::Base
  def health_check
    render json: {rails: "OK"}, status: :ok
  end

  def sign_out
    reset_session
    redirect_to root_path
  end
end
