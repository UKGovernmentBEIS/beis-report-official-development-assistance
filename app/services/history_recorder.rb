class HistoryRecorder
  INTERNAL_VALUES = ["form_state"].freeze

  def initialize(user:)
    @user = user
  end

  def call(changes:, reference:, activity:, trackable:, report: nil)
    changes
      .each do |value_changed, (previous_value, new_value)|
      next if INTERNAL_VALUES.include?(value_changed)

      HistoricalEvent.create(
        user: user,
        activity: activity,
        trackable: trackable,
        report: report,
        reference: reference,
        value_changed: value_changed,
        previous_value: previous_value,
        new_value: new_value,
      )
    end
  end

  private

  attr_reader :user
end
