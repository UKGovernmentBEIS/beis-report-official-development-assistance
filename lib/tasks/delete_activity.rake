desc "Deletes the activity and associations"
namespace :activities do
  task delete: :environment do
    activity_id = ENV["ID"]

    abort "You must specify a database ID for an activity e.g. `ID=8c3b69ec-1e9c-49ae-8e04-7c5d3826b253`)" if activity_id.nil?

    activity = Activity.find activity_id

    children = activity.children
    descendents = activity.descendants
    actuals = Actual.where(parent_activity_id: activity.id)
    refunds = Refund.where(parent_activity_id: activity.id)
    budgets = Budget.where(parent_activity_id: activity.id)
    forecasts = Forecast.unscoped.where(parent_activity_id: activity.id)
    comment_count = activity.comments.count
    matched_effort = MatchedEffort.where(activity_id: activity.id)
    external_income = ExternalIncome.where(activity_id: activity.id)
    history = HistoricalEvent.where(activity_id: activity.id)
    adjustments = Adjustment.where(parent_activity_id: activity.id)
    implementing_organisations = OrgParticipation.where(activity_id: activity.id)
    incomming_transfers_count = IncomingTransfer.where(destination_id: activity.id).count
    outgoing_transfers_count = OutgoingTransfer.where(source_id: activity.id).count

    Kernel.puts "\nActivity: #{activity.id}\n"
    Kernel.puts "==============================================\n"
    Kernel.puts "title: #{activity.title}\n"
    Kernel.puts "fund: #{activity.source_fund.name}\n"
    Kernel.puts "level: #{activity.level}\n"
    Kernel.puts "----------------------------------------------\n"
    Kernel.puts "# descendents: #{descendents.count}\n"
    Kernel.puts "# children: #{children.count}\n"
    Kernel.puts "# actual spend entires: #{actuals.count}\n"
    Kernel.puts "# refund entires: #{refunds.count}\n"
    Kernel.puts "# budget entries: #{budgets.count}\n"
    Kernel.puts "# forecast entries: #{forecasts.count}\n"
    Kernel.puts "# incoming transfer entries: #{incomming_transfers_count}"
    Kernel.puts "# outgoing transfer entries: #{outgoing_transfers_count}"
    Kernel.puts "# comments: #{comment_count}\n"
    Kernel.puts "# matched effort entries: #{matched_effort.count}\n"
    Kernel.puts "# external income entires: #{external_income.count}\n"
    Kernel.puts "# history entries: #{history.count}\n"
    Kernel.puts "# adjustment entries: #{adjustments.count}\n"
    Kernel.puts "# implementing organisations: #{implementing_organisations.count}\n"

    Kernel.puts "\nAre you sure you want to delete this activity, all descendants and associated entities? [y/n]\n"
    answer = $stdin.gets.chomp
    case answer
    when "y"
      delete_activity(activity_id: activity.id)
    when "n"
      Kernel.puts "Not deleting the activity with ID #{activity.id}"
      abort
    else
      Kernel.puts "Unrecognised response, answer 'y' or 'n'"
    end
  rescue ActiveRecord::RecordNotFound
    abort "Cannot find an activity with ID #{activity_id}"
  end
end

def delete_activity(activity_id:)
  activity = Activity.find(activity_id)

  if activity.children.any?
    Kernel.puts "----------------------------------------------\n"
    Kernel.puts "Deleting children of activity with ID #{activity.id}\n"
    activity.children.each do |child_activity|
      delete_activity(activity_id: child_activity.id)
    end
  end

  actuals_deleted = Actual.destroy_by(parent_activity_id: activity_id)
  refunds_deleted = Refund.destroy_by(parent_activity_id: activity_id)
  adjustments_deleted = Adjustment.destroy_by(parent_activity_id: activity_id)
  budgets_deleted = Budget.destroy_by(parent_activity_id: activity_id)
  forecasts_deleted = Forecast.unscoped.destroy_by(parent_activity_id: activity_id)
  comments_deleted = activity.comments.destroy_all
  matched_effort_deleted = MatchedEffort.destroy_by(activity_id: activity_id)
  external_income_deleted = ExternalIncome.destroy_by(activity_id: activity_id)
  incomming_transfers_deleted = IncomingTransfer.destroy_by(destination_id: activity_id)
  outgoing_transfers_deleted = OutgoingTransfer.destroy_by(source_id: activity_id)

  Kernel.puts "\n==============================================\n"
  Kernel.puts "Deleted associations for activity with ID #{activity_id}\n"
  Kernel.puts "----------------------------------------------\n"
  Kernel.puts "#{actuals_deleted.count} actuals deleted\n"
  Kernel.puts "#{refunds_deleted.count} refunds deleted\n"
  Kernel.puts "#{adjustments_deleted.count} adjustments deleted\n"
  Kernel.puts "#{budgets_deleted.count} budgets deleted\n"
  Kernel.puts "#{forecasts_deleted.count} forecasts deleted\n"
  Kernel.puts "#{comments_deleted.count} comments deleted\n"
  Kernel.puts "#{matched_effort_deleted.count} matched effort entries deleted\n"
  Kernel.puts "#{external_income_deleted.count} external income entries deleted\n"
  Kernel.puts "#{incomming_transfers_deleted.count} incoming transfer entries deleted\n"
  Kernel.puts "#{outgoing_transfers_deleted.count} outgoing transfer entries deleted\n"
  Kernel.puts "----------------------------------------------\n"

  activity.destroy
  Kernel.puts "Activity with ID #{activity.id} deleted"
end
