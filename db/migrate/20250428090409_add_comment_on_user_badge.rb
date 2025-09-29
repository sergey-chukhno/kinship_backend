class AddCommentOnUserBadge < ActiveRecord::Migration[7.1]
  def change
    add_column :user_badges, :comment, :text
  end
end
