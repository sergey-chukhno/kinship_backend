class AddParticipantsNumberAndStatusAndTimeSpentToProject < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :participants_number, :integer
    add_column :projects, :status, :integer
    add_column :projects, :time_spent, :integer
  end
end
