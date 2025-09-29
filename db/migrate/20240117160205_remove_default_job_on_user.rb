class RemoveDefaultJobOnUser < ActiveRecord::Migration[7.0]
  def change
    change_column_default :users, :job, nil
  end
end
