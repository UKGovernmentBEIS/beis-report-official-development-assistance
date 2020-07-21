# frozen_string_literal: true

class SubmissionPresenter < SimpleDelegator
  def state
    return if super.blank?
    I18n.t("label.submission.state.#{super.downcase}")
  end
end
