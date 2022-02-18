class ErrorsController < ApplicationController
  include Auth
  include Pundit::Authorization

  def not_found
    render "pages/errors/not_found",
      status: 404
  end

  def internal_server_error
    render "pages/errors/internal_server_error",
      status: 500
  end

  def unacceptable
    render "pages/errors/unacceptable",
      status: 422
  end
end
