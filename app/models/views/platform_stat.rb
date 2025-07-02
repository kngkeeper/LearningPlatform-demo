class Views::PlatformStat < ApplicationRecord
  self.table_name = "platform_stats"

  # This is a database view, so it's read-only
  def readonly?
    true
  end

  # Since this view returns a single row with aggregated data,
  # we can use a singleton pattern
  def self.current
    first
  end
end
