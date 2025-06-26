class CreatePurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :purchases do |t|
      t.boolean :active
      t.belongs_to :student, null: false, foreign_key: true
      t.belongs_to :payment_method, null: false, foreign_key: true
      t.references :purchaseable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
