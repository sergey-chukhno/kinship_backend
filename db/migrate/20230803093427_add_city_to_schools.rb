class AddCityToSchools < ActiveRecord::Migration[7.0]
  def change
    add_column :schools, :city, :string
  end
end
