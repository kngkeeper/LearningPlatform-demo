class School < ApplicationRecord
  has_many :students, dependent: :destroy
  has_many :terms, dependent: :destroy
  has_many :courses, through: :terms
  has_many :licenses, dependent: :destroy
  belongs_to :admin, class_name: "User", optional: true

  validates :name, presence: true, uniqueness: true
end
