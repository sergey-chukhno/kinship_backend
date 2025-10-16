class CreatePartnershipMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :partnership_members do |t|
      t.references :partnership, null: false, foreign_key: true
      t.references :participant, polymorphic: true, null: false
      t.integer :member_status, default: 0, null: false
      t.integer :role_in_partnership, default: 0, null: false
      t.datetime :joined_at
      t.datetime :confirmed_at

      t.timestamps
    end
    
    add_index :partnership_members, [:participant_type, :participant_id]
    add_index :partnership_members, [:partnership_id, :participant_id, :participant_type], 
              name: 'index_partnership_members_unique', unique: true
    add_index :partnership_members, :member_status
    add_index :partnership_members, :role_in_partnership
  end
end
