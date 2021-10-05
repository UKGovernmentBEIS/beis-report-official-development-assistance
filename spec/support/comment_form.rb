class CommentForm
  include Capybara::DSL
  include RSpec::Matchers

  attr_reader :comment, :report

  def initialize(report:)
    @report = report
  end

  class << self
    include Rails.application.routes.url_helpers
    include Capybara::DSL

    def create(report:)
      visit report_path(report)
      click_on I18n.t("tabs.report.variance.heading")
      click_on I18n.t("table.body.report.add_comment")

      new(report: report)
    end

    def edit_from_activity_page(report:, comment:)
      visit organisation_activity_comments_path(comment.activity.organisation, comment.activity)

      click_link I18n.t("default.link.edit"), href: edit_activity_comment_path(comment.activity, comment)

      new(report: report)
    end
  end

  def complete(comment:)
    @comment = comment
    fill_in "comment[comment]", with: comment
    click_button I18n.t("default.button.submit")
  end

  def has_report_summary_information?
    within(".govuk-summary-list") do
      expect(page).to have_content I18n.l(report.deadline)
      expect(page).to have_content I18n.t("label.report.state.#{report.state}")
    end
  end
end
