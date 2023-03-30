class BudgetsController < BaseController
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

    result = CreateBudget.new(activity: @activity).call(attributes: create_budget_params)
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
    @budget_presenter = BudgetPresenter.new(@budget)
    @current_value = @budget_presenter.value

    authorize @budget

    @activity = Activity.find(activity_id)

    prepare_default_activity_trail(@activity)
    add_breadcrumb t("breadcrumb.budget.edit"), edit_activity_budget_path(@activity, @budget)
  end

  def update
    @budget = Budget.find(id)
    @budget_presenter = BudgetPresenter.new(@budget)
    @current_value = @budget_presenter.value

    authorize @budget

    @activity = Activity.find(activity_id)
    result = UpdateBudget.new(budget: @budget, user: current_user)
      .call(attributes: update_budget_params)

    if result.success?
      flash[:notice] = t("action.budget.update.success",
        financial_year: @budget_presenter.financial_year,
        value: @budget_presenter.value)
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

  def revisions
    @activity = Activity.find(activity_id)
    budget = Budget.find(params[:budget_id])

    authorize budget

    @audits = budget.audits

    prepare_default_activity_trail(@activity)
    add_breadcrumb t("breadcrumb.budget.revisions"), activity_budget_revisions_path(budget.parent_activity_id, budget)
  end

  private

  def id
    params[:id]
  end

  def activity_id
    params[:activity_id]
  end

  def create_budget_params
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

  def update_budget_params
    params.require(:budget).permit(:value, :audit_comment)
  end
end
