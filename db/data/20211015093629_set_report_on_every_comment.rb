# Run me with `rails runner db/data/20211015093629_set_report_on_every_comment.rb`

# This adds a data migration to build on the previous commit to make sure all comments
# have an associated report. It runs through all  the comments with no report,
# and sets the report id to the report that is associated with either the comment's
# Refund or Adjustment (known in the comment model as the  `commentable`)

comments = Comment.where(report: nil)

puts "Fixing up #{comments.count} comments..."

comments.each do |comment|
  comment.update!(report_id: comment.commentable.report.id)
end

puts "-> there are now #{comments.reload.count} comments still to fix"
