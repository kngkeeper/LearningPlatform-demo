class Views::SchoolStat < ApplicationRecord
  self.table_name = "school_stats"
  self.primary_key = "school_id"

  # This is a database view, so it's read-only
  def readonly?
    true
  end

  # Association to access the actual school data
  belongs_to :school, foreign_key: "school_id"
end
