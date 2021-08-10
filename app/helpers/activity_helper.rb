module ActivityHelper
  include CodelistHelper

  def step_is_complete_or_next?(activity:, step:)
    steps = Activity::FORM_STEPS

    return false if activity.form_state.nil?
    return true if activity.form_steps_completed?
    return true if activity.fund? && step == :identifier

    presenter_position = steps.index(step.to_sym)
    activity_position = steps.index(activity.form_state.to_sym)

    presenter_position <= activity_position + 1
  end

  def link_to_activity_parent(parent:, user:)
    return if parent.nil?
    return parent.title if parent.fund? && user.delivery_partner?
    link_to parent.title, organisation_activity_path(parent.organisation, parent), {class: "govuk-link govuk-link--no-visited-state"}
  end

  def custom_capitalisation(level)
    "#{level.chars.first.upcase}#{level[1..-1]}"
  end

  def sdg_options
    I18n.t("form.label.activity.sdg_options")
  end

  def policy_markers_iati_codes_to_enum(code)
    Activity::POLICY_MARKER_CODES.key(code.to_i)
  end

  def policy_markers_desertification_iati_codes_to_enum(code)
    Activity::DESERTIFICATION_POLICY_MARKER_CODES.key(code.to_i)
  end

  def benefitting_countries_with_percentages(benefitting_countries)
    return [] if benefitting_countries.blank?

    # Get an equal percentage split between all the countries
    # (together with the remainder if possible)
    percentage, remainder = 100.divmod(benefitting_countries.count)

    benefitting_countries.map do |country|
      # If we're at the last item, add the remainder to the percentage
      # split
      percentage += remainder if country == benefitting_countries.last

      OpenStruct.new(code: country,
                     name: country_name_from_code(country),
                     percentage: percentage.to_f)
    end
  end
end
