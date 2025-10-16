class CreatePartnerships < ActiveRecord::Migration[7.1]
  def change
    create_table :partnerships do |t|
      t.references :initiator, polymorphic: true, null: false
      t.integer :status, default: 0, null: false
      t.integer :partnership_type, default: 0, null: false
      t.boolean :share_members, default: false, null: false
      t.boolean :share_projects, default: true, null: false
      t.boolean :has_sponsorship, default: false, null: false
      t.string :name
      t.text :description
      t.datetime :confirmed_at

      t.timestamps
    end
    
    add_index :partnerships, [:initiator_type, :initiator_id]
    add_index :partnerships, :status
    add_index :partnerships, :partnership_type
    add_index :partnerships, :confirmed_at
  end
end
