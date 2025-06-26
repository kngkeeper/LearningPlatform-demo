class User < ApplicationRecord
  enum :role, { student: 0, school_admin: 1, platform_admin: 2 }

  # Default devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :student, dependent: :destroy
  has_one :school, through: :student

  # For school admins
  has_one :managed_school, class_name: "School", foreign_key: "admin_id"

  # Add stricter email validation than Devise's default
  validates :email, format: {
    with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i,
    message: "is invalid"
  }
end
