# Run me with `rails runner db/data/20211005131155_move_legacy_comments_to_comments.rb`

# This migrates the old, legacy comments to the new polymorphic comment table.
# There are some legacy comments that either have no comment at all, or are
# related to an activity that no longer exists, so we skip creating a
# new comment for these, but keep a record to report at the end.

legacy_comments = LegacyComment.all

puts "Migrating #{legacy_comments.count} comments..."

comments_without_comment = []
comments_without_activity = []
created_comments = []

ActiveRecord::Base.transaction do
  legacy_comments.each do |legacy_comment|
    if legacy_comment.comment.blank?
      comments_without_comment << legacy_comment
    elsif legacy_comment.activity.blank?
      comments_without_activity << legacy_comment
    else
      Comment.create!(
        body: legacy_comment.comment,
        commentable_id: legacy_comment.activity_id,
        commentable_type: "Activity",
        owner_id: legacy_comment.owner_id,
        report_id: legacy_comment.report_id,
        created_at: legacy_comment.created_at,
        updated_at: legacy_comment.updated_at,
      )

      created_comments << legacy_comment
    end
  end
end

puts "#{created_comments.count} of #{legacy_comments.count} comments created"
puts "#{comments_without_activity.count} legacy comments had no activity, so were skipped"
puts "#{comments_without_comment.count} legacy comments had no comment body, so were skipped"
