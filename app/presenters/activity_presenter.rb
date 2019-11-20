# frozen_string_literal: true

class ActivityPresenter < SimpleDelegator
  def aid_type
    super.downcase
  end
end
