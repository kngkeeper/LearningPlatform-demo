class Views::CourseEnrollmentStat < ApplicationRecord
  self.table_name = "course_enrollment_stats"
  self.primary_key = "course_id"

  # This is a database view, so it's read-only
  def readonly?
    true
  end

  # Associations to access the actual course data
  belongs_to :course, foreign_key: "course_id"
  belongs_to :school, foreign_key: "school_id"
  belongs_to :term, foreign_key: "term_id"

  # Scope for filtering by school
  scope :for_school, ->(school) { where(school_id: school.id) }
end
