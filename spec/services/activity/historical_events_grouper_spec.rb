require "rails_helper"

RSpec.describe Activity::HistoricalEventsGrouper do
  let(:user1) { create(:delivery_partner_user, email: "john@example.com") }
  let(:user2) { create(:delivery_partner_user, email: "fred@example.com") }
  let(:activity) { create(:project_activity) }

  let!(:event1) do
    HistoricalEvent.create(
      activity: activity,
      reference: "Update to Activity programme_status",
      user: user1,
      created_at: Time.zone.parse("02-Jul-2021 12:08")
    )
  end
  let!(:event2) do
    HistoricalEvent.create(
      activity: activity,
      reference: "Update to Activity programme_status",
      user: user1,
      created_at: Time.zone.parse("02-Jul-2021 12:08")
    )
  end

  let!(:event3) do
    HistoricalEvent.create(
      activity: activity,
      reference: "Import from CSV",
      user: user2,
      created_at: Time.zone.parse("07-Jul-2021 10:45")
    )
  end
  let!(:event4) do
    HistoricalEvent.create(
      activity: activity,
      reference: "Import from CSV",
      user: user2,
      created_at: Time.zone.parse("07-Jul-2021 10:45")
    )
  end

  it "groups events using a combination of reference, user.email and time" do
    expect(Activity::HistoricalEventsGrouper.new(activity: activity).call).to eq(
      {
        {
          reference: "Update to Activity programme_status",
          user: "john@example.com",
          timestamp: "02 Jul 2021 at 12:08",
        } => [event1, event2],

        {
          reference: "Import from CSV",
          user: "fred@example.com",
          timestamp: "07 Jul 2021 at 10:45",
        } => [event3, event4],
      }
    )
  end
end
