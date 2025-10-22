class CreateBranchRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :branch_requests do |t|
      # Polymorphic parent (Company or School that will become parent)
      t.string :parent_type, null: false
      t.bigint :parent_id, null: false
      
      # Polymorphic child (Company or School that will become branch)
      t.string :child_type, null: false
      t.bigint :child_id, null: false
      
      # Polymorphic initiator (Company or School that initiated the request)
      t.string :initiator_type, null: false
      t.bigint :initiator_id, null: false
      
      # Request status: pending, confirmed, rejected
      t.integer :status, default: 0, null: false
      
      # Optional message from initiator
      t.text :message
      
      # Timestamp when confirmed
      t.datetime :confirmed_at

      t.timestamps
    end
    
    # Indexes for polymorphic associations
    add_index :branch_requests, [:parent_type, :parent_id]
    add_index :branch_requests, [:child_type, :child_id]
    add_index :branch_requests, [:initiator_type, :initiator_id]
    add_index :branch_requests, :status
    
    # Unique constraint: one request per parent-child pair
    add_index :branch_requests, [:parent_type, :parent_id, :child_type, :child_id], 
              unique: true, 
              name: 'index_branch_requests_on_parent_and_child'
    
    say "Created branch_requests table with polymorphic associations"
    say "Supports Company-Company, School-School, and cross-type branching if needed"
  end
end
