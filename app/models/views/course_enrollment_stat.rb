# Read-only model representing a database view for course enrollment statistics.
#
# This view aggregates enrollment data per course to provide efficient access
# to commonly requested analytics without expensive real-time calculations.
# Used by the dashboard service to display course-level enrollment metrics.
#
# The underlying database view should include:
# - course_id, school_id, term_id for associations
# - students_enrolled, credit_card_enrollments, license_enrollments counts
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
