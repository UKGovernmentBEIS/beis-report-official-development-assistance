class BreadcrumbContext
  def initialize(session)
    @session = session
  end

  def set(type:, model:)
    session[:breadcrumb_context] = {
      type: type,
      model: model,
    }
  end

  def reset!
    session[:breadcrumb_context] = {}
  end

  def empty?
    session[:breadcrumb_context].blank?
  end

  def type
    session.dig(:breadcrumb_context, :type)
  end

  def model
    session.dig(:breadcrumb_context, :model)
  end

  private

  attr_reader :session
end
