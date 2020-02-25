class ImplementingOrganisationPresenter < SimpleDelegator
  include CodelistHelper

  def organisation_type
    return if super.blank?
    type = organisation_types.find { |type| type.code == super }
    type.name
  end

  private

  def organisation_types
    yaml_to_objects(entity: "organisation", type: "organisation_type", with_empty_item: false)
  end
end
