class ReportPage
  include Rails.application.routes.url_helpers
  include Capybara::DSL
  include RSpec::Matchers

  def initialize(report)
    visit reports_path

    within "##{report.id}" do
      click_on I18n.t("default.link.show")
    end
  end

  def visit_comments_page
    within ".govuk-tabs" do
      click_on I18n.t("tabs.report.comments.heading")
    end
  end

  def has_comments_grouped_by_activity?(activities:, comments:)
    within ".govuk-table" do
      expect(page.find_all("th[scope=rowgroup]").count).to eq(activities.count)
      expect(page.find_all("tbody tr").count).to eq(comments.count)

      activities.each do |activity|
        comments_for_activity = comments.select { |c| c.activity_id == activity.id }

        within "tbody##{activity.id}" do
          within "th" do
            expect(page).to have_content(activity.roda_identifier)
          end

          comments_for_activity.each do |comment|
            expect(page).to have_content(I18n.l(comment.created_at.to_date))
            expect(page).to have_content(comment.comment)
          end
        end
      end
    end
  end

  def has_edit_buttons_for_comments?(comments)
    within ".govuk-table" do
      comments.all? do |comment|
        page.has_link?(href: edit_activity_comment_path(comment.activity, comment))
      end
    end
  end
end
