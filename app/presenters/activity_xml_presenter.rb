# frozen_string_literal: true

class ActivityXmlPresenter < SimpleDelegator
  def iati_identifier
    "#{reporting_organisation_reference}-#{identifier}"
  end
end
