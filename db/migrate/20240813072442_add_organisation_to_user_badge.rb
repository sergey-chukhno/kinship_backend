class AddOrganisationToUserBadge < ActiveRecord::Migration[7.0]
  def change
    add_reference :user_badges, :organization, polymorphic: true, index: true, null: false
  end
end
