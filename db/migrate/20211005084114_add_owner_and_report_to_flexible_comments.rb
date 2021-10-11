class AddOwnerAndReportToFlexibleComments < ActiveRecord::Migration[6.1]
  def change
    add_reference :flexible_comments, :owner, type: :uuid
    add_reference :flexible_comments, :report, type: :uuid
  end
end
