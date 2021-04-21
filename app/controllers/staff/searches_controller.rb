class Staff::SearchesController < Staff::BaseController
  include Secured

  def show
    skip_authorization
    @activity_search = ActivitySearch.new(user: current_user, query: params[:query])
  end
end
