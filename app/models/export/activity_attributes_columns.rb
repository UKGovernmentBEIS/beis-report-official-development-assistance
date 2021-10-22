class Export::ActivityAttributesColumns
  IGNORED_ATTRIBUTES = [
    :created_at,
    :updated_at,
    :id,
    :organisation_id,
    :form_state,
    :extending_organisation_id,
    :geography,
    :parent_id,
  ]

  def initialize(activities:, attributes:)
    @activities = activities
    @attributes = clean_attrbutes(attributes)
  end

  def headers
    @attributes.map { |att| I18n.t("activerecord.attributes.activity.#{att}") }
  end

  def rows
    @activities.map { |activity|
      values = @attributes.map { |att|
        ActivityCsvPresenter.new(activity).send(att)
      }
      [activity.id, values]
    }.to_h
  end

  private

  def clean_attrbutes(attributes)
    attributes.reject do |att|
      attribute_error(att) unless Activity.has_attribute?(att)
      IGNORED_ATTRIBUTES.include?(att)
    end
  end

  def attribute_error(attribute)
    raise ActiveRecord::UnknownAttributeError.new(Activity, attribute)
  end
end
