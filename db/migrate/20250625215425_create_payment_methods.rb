class CreatePaymentMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_methods do |t|
      t.integer :method_type
      t.json :details
      t.belongs_to :student, null: false, foreign_key: true
      t.belongs_to :license, null: false, foreign_key: true

      t.timestamps
    end
  end
end
