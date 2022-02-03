class ApplicationController < ActionController::Base
  include Auth
  include Ip

  private

  def add_breadcrumb(name, path, options = {})
    super name, path, options.merge(title: name)
  end
end
