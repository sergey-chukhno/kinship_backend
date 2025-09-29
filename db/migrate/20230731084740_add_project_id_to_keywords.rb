class AddProjectIdToKeywords < ActiveRecord::Migration[7.0]
  def change
    add_reference :keywords, :project, null: false, foreign_key: true
  end
end
