module Searches
  module Breadcrumbed
    extend ActiveSupport::Concern

    def prepare_default_search_trail(search)
      BreadcrumbContext.new(session).set(type: :search, model: search)
      add_breadcrumb t("page_content.activity_search.heading", query: search.query), search_path(query: search.query)
    end
  end
end
