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
    return parent.title if parent.fund? && user.partner_organisation?
    link_to parent.title, organisation_activity_path(parent.organisation, parent), {class: "govuk-link govuk-link--no-visited-state"}
  end

  def show_link_to_add_comment?(activity:, report: nil)
    [
      is_commentable_programme?(activity: activity),
      is_commentable_project?(activity: activity, report: report)
    ].any?
  end

  def show_link_to_edit_comment?(comment:)
    [
      is_editable_programme_comment?(comment: comment),
      is_editable_non_programme_comment?(comment: comment)
    ].any?
  end

  def custom_capitalisation(level)
    "#{level[0].upcase}#{level[1..]}"
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

    benefitting_countries.map do |country|
      OpenStruct.new(
        code: country,
        name: country_name_from_code(country),
        percentage: 100 / benefitting_countries.count.to_f
      )
    end
  end

  def edit_comment_path_for(commentable, comment)
    case commentable.class.name
    when "Activity"
      edit_activity_comment_path(commentable, comment)
    when "Actual"
      edit_activity_actual_path(commentable.parent_activity, commentable)
    end
  end

  def can_download_as_xml?(activity:, user:)
    activity.project? && ProjectPolicy.new(user, activity).download? ||
      activity.third_party_project? && ThirdPartyProjectPolicy.new(user, activity).download?
  end

  def activity_csv_upload_file_field(builder:, recovered_from_error:, path_helper:, instance:, type:)
    default_id = GOVUKDesignSystemFormBuilder::Base.new(nil, builder.object_name, :activity_csv).field_id
    unique_id = [default_id, type.to_s.dasherize].join("--")
    default_hint_id = default_id.gsub("field", "hint")
    unique_hint_id = unique_id.gsub("field", "hint")

    label_translation_path = "form.label.activity.csv_file"
    label_translation_path += "_recover_from_error" if recovered_from_error

    hint_translation_path = "form.hint.activity.csv_file"
    hint_translation_path += "_recover_from_error_html" if recovered_from_error

    hint_text = recovered_from_error ?
      t(hint_translation_path, link: send(path_helper, instance, {type: type, format: :csv})) : t(hint_translation_path)

    field = builder.govuk_file_field :activity_csv,
      label: {text: t(label_translation_path), hidden: !recovered_from_error, for: unique_id},
      hint: {text: hint_text, id: unique_hint_id},
      id: unique_id

    field.gsub("aria-describedby=\"#{default_hint_id}\"", "aria-describedby=\"#{unique_hint_id}\"")
  end

  private

  def is_commentable_programme?(activity:)
    activity.programme? && policy(:level_b).create_activity_comment?
  end

  def is_commentable_project?(activity:, report: nil)
    activity.is_project? && policy([:activity, :comment]).create? && report
  end

  def is_editable_programme_comment?(comment:)
    comment.commentable.try(:programme?) && policy(:level_b).update_activity_comment?
  end

  def is_editable_non_programme_comment?(comment:)
    return false if comment.commentable.try(:programme?)

    policy([comment.commentable, comment]).update?
  end
end
