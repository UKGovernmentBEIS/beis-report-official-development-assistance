# frozen_string_literal: true

class Staff::LevelB::Budgets::UploadsController < Staff::BaseController
  include Secured

  def new
    authorize :level_b, :budget_upload?
  end
end
