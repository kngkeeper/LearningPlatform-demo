class AddPriceToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :price, :decimal
  end
end
