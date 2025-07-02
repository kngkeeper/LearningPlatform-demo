class Views::TermStat < ApplicationRecord
  self.table_name = "term_stats"
  self.primary_key = "term_id"

  # This is a database view, so it's read-only
  def readonly?
    true
  end

  # Association to access the actual term data
  belongs_to :term, foreign_key: "term_id"
  belongs_to :school, foreign_key: "school_id"

  # Scope for filtering by school
  scope :for_school, ->(school) { where(school_id: school.id) }
end
