class CreateParentChildInfos < ActiveRecord::Migration[7.1]
  def change
    create_table :parent_child_infos do |t|
      t.references :parent_user, null: false, foreign_key: { to_table: :users }, index: true
      t.string :first_name
      t.string :last_name
      t.date :birthday
      t.references :school, null: true, foreign_key: true
      t.string :school_name
      t.bigint :class_id, null: true
      t.string :class_name
      t.references :linked_user, null: true, foreign_key: { to_table: :users }, index: true

      t.timestamps
    end

    # Add foreign key constraint for class_id (school_level_id)
    add_foreign_key :parent_child_infos, :school_levels, column: :class_id

    # Composite index for matching children by name + birthday + school
    add_index :parent_child_infos, [:first_name, :last_name, :birthday], name: 'index_parent_child_infos_on_name_and_birthday'
  end
end
