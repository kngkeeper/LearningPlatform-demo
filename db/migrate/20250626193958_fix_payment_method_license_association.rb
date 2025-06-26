class FixPaymentMethodLicenseAssociation < ActiveRecord::Migration[8.0]
  def change
    # Make license_id nullable since credit card payments don't need licenses
    change_column_null :payment_methods, :license_id, true
  end
end
