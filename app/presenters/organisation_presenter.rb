# frozen_string_literal: true

class OrganisationPresenter < SimpleDelegator
  def language_code
    super.downcase
  end

  def default_currency
    super.downcase
  end
end
