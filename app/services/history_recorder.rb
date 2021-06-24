class HistoryRecorder
  def initialize(user:)
    @user = user
  end

  def call(changes:, reference:, activity:)
    changes.each do |value_changed, (previous_value, new_value)|
      HistoricalEvent.create(
        user: user,
        activity: activity,
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
