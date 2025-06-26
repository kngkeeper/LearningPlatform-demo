class AddCriticalIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :enrollments, [ :enrollable_type, :enrollable_id ]
    add_index :purchases, [ :purchaseable_type, :purchaseable_id ]

    # Add compound index for enrollment access checks
    add_index :enrollments, [ :student_id, :enrollable_id, :enrollable_type ], name: 'idx_enrollments_access_check'

    # Add unique index on license codes
    add_index :licenses, :code, unique: true

    # Add partial index for active licenses per school
    add_index :licenses, [ :school_id, :status ], where: "status = 0"

    # Add index on purchase active status
    add_index :purchases, :active

    # Add index on payment method types
    add_index :payment_methods, :method_type
  end
end
