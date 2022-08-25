class Export::ActivityAttributesColumns
  IGNORED_ATTRIBUTES = [
    :created_at,
    :updated_at,
    :id,
    :organisation_id,
    :form_state,
    :extending_organisation_id,
    :geography,
    :parent_id
  ]

  DYNAMIC_ATTRIBUTES = [
    :benefitting_region,
    :flow,
    :finance,
    :tied_status,
    :parent_programme_identifier,
    :parent_programme_title,
    :parent_project_identifier,
    :parent_project_title
  ]

  def initialize(activities:, attributes:)
    @activities = activities
    @attributes = clean_attributes(attributes)
  end

  def headers
    @attributes.map { |att| I18n.t("activerecord.attributes.activity.#{att}") }
  end

  def rows
    return [] if @activities.empty?
    @activities.includes([:parent]).map { |activity|
      presenter = ActivityCsvPresenter.new(activity)
      values = @attributes.map { |att| presenter.send(att) }
      [activity.id, values]
    }.to_h
  end

  private

  def clean_attributes(attributes)
    attributes.reject do |att|
      next if DYNAMIC_ATTRIBUTES.include?(att)
      attribute_error(att) unless Activity.has_attribute?(att)
      IGNORED_ATTRIBUTES.include?(att)
    end
  end

  def attribute_error(attribute)
    raise ActiveRecord::UnknownAttributeError.new(Activity, attribute)
  end
end
