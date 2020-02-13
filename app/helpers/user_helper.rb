# frozen_string_literal: true

module UserHelper
  def organisation_check_box_options
    @organisation_check_box_options ||=
      Organisation.sorted_by_name.map { |o| [o.name, o.id] }
  end
end
