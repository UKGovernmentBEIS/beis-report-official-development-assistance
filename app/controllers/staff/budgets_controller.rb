class Staff::BudgetsController < Staff::BaseController
  include Secured

  def new
    @activity = Activity.find(activity_id)
    @budget = Budget.new
    @budget.parent_activity = @activity

    authorize @budget
  end

  def create
    @activity = Activity.find(activity_id)
    authorize @activity

    result = CreateBudget.new(activity: @activity).call(attributes: budget_params)

    if result.success?
      flash[:notice] = I18n.t("form.budget.create.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      @budget = result.object
      render :new
    end
  end

  def edit
    @budget = Budget.find(id)
    authorize @budget

    @activity = Activity.find(activity_id)
  end

  def update
    @budget = Budget.find(id)
    authorize @budget

    @activity = Activity.find(activity_id)
    result = UpdateBudget.new(budget: @budget)
      .call(attributes: budget_params)

    if result.success?
      flash[:notice] = I18n.t("form.budget.update.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :edit
    end
  end

  private

  def id
    params[:id]
  end

  def activity_id
    params[:activity_id]
  end

  def budget_params
    params.require(:budget).permit(
      :budget_type,
      :status,
      :value,
      :period_start_date,
      :period_end_date,
      :currency
    )
  end
end
