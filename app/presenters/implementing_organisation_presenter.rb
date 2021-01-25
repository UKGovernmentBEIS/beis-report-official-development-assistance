class ImplementingOrganisationPresenter < SimpleDelegator
  include CodelistHelper

  def organisation_type
    return if super.blank?
    type = organisation_types.find { |type| type.code == super }
    type.name
  end

  private

  def organisation_types
    Codelist.new(type: "organisation_type").to_objects(with_empty_item: false)
  end
end
