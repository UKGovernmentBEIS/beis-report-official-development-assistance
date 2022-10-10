class Staff::SearchesController < Staff::BaseController
  include Secured
  include Searches::Breadcrumbed

  def show
    skip_authorization

    @activity_search = ActivitySearch.new(user: current_user, query: params[:query])
    prepare_default_search_trail(@activity_search)
  end
end
