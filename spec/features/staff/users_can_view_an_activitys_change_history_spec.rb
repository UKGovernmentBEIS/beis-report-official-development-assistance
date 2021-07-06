RSpec.feature "Users can view an activity's 'Change History' within a tab" do
  context "as a Delivery Partner user" do
    let(:user) { create(:delivery_partner_user) }
    let(:programme) { create(:programme_activity) }
    let(:activity) { create(:project_activity, organisation: user.organisation, parent: programme) }
    let(:report) do
      create(
        :report,
        :active,
        organisation: programme.organisation,
        fund: programme.parent,
        financial_quarter: 3,
        financial_year: 2020,
      )
    end

    let(:reference) { "Update to Activity purpose" }
    let(:changes) do
      {"title" => ["Original title", "Updated title"],
       "description" => ["Original description", "Updated description"],}
    end

    before do
      authenticate!(user: user)
    end

    def setup_historical_events(report:)
      HistoryRecorder
        .new(user: user)
        .call(changes: changes, activity: activity, reference: reference, report: report)
    end

    def expect_to_see_change_history_with_reference(reference:, events:)
      fail "We expect to see some Historical Events!" if events.empty?

      within ".historical-events" do
        expect(page).to have_css(".historical_event", count: events.count)
        expect(page).to have_css(".reference", text: reference)

        events.each do |event|
          within "#historical_event_#{event.id}" do
            expect(page).to have_css(".property", text: event.value_changed)
            expect(page).to have_css(".previous-value", text: event.previous_value)
            expect(page).to have_css(".new-value", text: event.new_value)
            expect(page).to have_css(".user", text: event.user.email)
            expect(page).to have_css(".timestamp", text: event.created_at.strftime("%d/%m/%C at %R"))
            if event.report
              expect(page).to have_css(
                ".report a[href='#{report_path(event.report)}']",
                text: event.report.financial_quarter_and_year
              )
            end
          end
        end
      end
    end

    scenario "the activities page contains a _Change History_ tab" do
      setup_historical_events(report: report)

      visit organisation_activity_path(activity.organisation, activity)

      click_link "Change history"

      expect(page).to have_css("h2", text: t("page_title.activity.change_history"))
      expect(page).to have_content(t("page_content.tab_content.change_history.guidance"))

      expect_to_see_change_history_with_reference(
        events: HistoricalEvent.last(2),
        reference: reference
      )
    end

    context "when the history is not associated with a report" do
      scenario "the _Change History_ is represented without error" do
        setup_historical_events(report: nil)

        visit organisation_activity_path(activity.organisation, activity)

        click_link "Change history"

        expect_to_see_change_history_with_reference(
          events: HistoricalEvent.last(2),
          reference: reference
        )
      end
    end
  end
end
