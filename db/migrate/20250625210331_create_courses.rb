class CreateCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :courses do |t|
      t.string :name
      t.belongs_to :term, null: false, foreign_key: true

      t.timestamps
    end
  end
end
