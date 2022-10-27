module CommentsHelper
  def comments_formatted_for_csv(comments)
    comments.pluck(:body).map(&:strip).join("|")
  end
end
