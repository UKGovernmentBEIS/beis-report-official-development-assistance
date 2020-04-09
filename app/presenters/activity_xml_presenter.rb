# frozen_string_literal: true

class ActivityXmlPresenter < SimpleDelegator
  def iati_identifier
    parent_activities.each_with_object([reporting_organisation.iati_reference]) { |parent, parent_identifiers|
      parent_identifiers << parent.identifier
    }.push(identifier).join("-")
  end
end
