class CreateLoggings < ActiveRecord::Migration[7.0]
  def change
    create_table :loggings do |t|
      t.string :ip_address, null: false
      t.string :request_path, null: false
      t.jsonb :request_path_params, null: false, default: {}
      t.integer :request_code, null: false
      t.datetime :request_time, null: false
      t.text :user_agent, null: false
      t.integer :user_id
      t.string :user_email

      t.timestamps
    end
  end
end
