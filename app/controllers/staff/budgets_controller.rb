class Staff::BudgetsController < Staff::BaseController
  include Secured
  include Activities::Breadcrumbed

  def new
    @activity = Activity.find(activity_id)
    @budget = Budget.new
    @budget.parent_activity = @activity
    @budget.budget_type = "direct"

    authorize @budget

    prepare_default_activity_trail(@activity)
    add_breadcrumb t("breadcrumb.budget.new"), new_activity_budget_path(@activity)
  end

  def create
    @activity = Activity.find(activity_id)
    authorize @activity

    result = CreateBudget.new(activity: @activity).call(attributes: budget_params)
    @budget = result.object

    if result.success?
      flash[:notice] = t("action.budget.create.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :new
    end
  end

  def edit
    @budget = Budget.find(id)
    authorize @budget

    @activity = Activity.find(activity_id)

    prepare_default_activity_trail(@activity)
    add_breadcrumb t("breadcrumb.budget.edit"), edit_activity_budget_path(@activity, @budget)
  end

  def update
    @budget = Budget.find(id)
    authorize @budget

    @activity = Activity.find(activity_id)
    result = UpdateBudget.new(budget: @budget)
      .call(attributes: budget_params)

    if result.success?
      flash[:notice] = t("action.budget.update.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :edit
    end
  end

  def destroy
    @activity = Activity.find(activity_id)
    @budget = Budget.find(id)

    authorize @budget

    @budget.destroy

    flash[:notice] = t("action.budget.destroy.success")
    redirect_to organisation_activity_path(@activity.organisation, @activity)
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
      :value,
      :financial_year,
      :currency,
      :funding_type,
      :providing_organisation_id,
      :providing_organisation_name,
      :providing_organisation_type,
      :providing_organisation_reference
    )
  end

  def find_activity
  end
end
