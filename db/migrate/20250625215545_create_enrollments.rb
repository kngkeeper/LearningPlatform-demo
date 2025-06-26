class CreateEnrollments < ActiveRecord::Migration[8.0]
  def change
    create_table :enrollments do |t|
      t.belongs_to :student, null: false, foreign_key: true
      t.belongs_to :purchase, null: false, foreign_key: true
      t.references :enrollable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
