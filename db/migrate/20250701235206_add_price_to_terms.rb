class AddPriceToTerms < ActiveRecord::Migration[8.0]
  def change
    add_column :terms, :price, :decimal
  end
end
