# frozen_string_literal: true

module UserHelper
  def organisation_check_box_options
    @organisation_check_box_options ||=
      Organisation.all.map { |o| [o.name, o.id] }
  end
end
