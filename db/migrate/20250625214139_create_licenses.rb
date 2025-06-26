class CreateLicenses < ActiveRecord::Migration[8.0]
  def change
    create_table :licenses do |t|
      t.string :code
      t.integer :status
      t.datetime :redeemed_at
      t.belongs_to :school, null: false, foreign_key: true
      t.belongs_to :term, null: false, foreign_key: true

      t.timestamps
    end
  end
end
