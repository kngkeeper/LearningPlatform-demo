class AddAdminIdToSchools < ActiveRecord::Migration[8.0]
  def change
    add_column :schools, :admin_id, :bigint
    add_index :schools, :admin_id
  end
end
