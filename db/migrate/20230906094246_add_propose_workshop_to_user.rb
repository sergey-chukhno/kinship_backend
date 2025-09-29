class AddProposeWorkshopToUser < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.boolean :propose_workshop, default: false
    end
  end
end
