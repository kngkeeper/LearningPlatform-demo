# Creates optimized database views for dashboard analytics and reporting.
#
# NOTE: This migration is deprecated. Database views are now managed through
# the db:create_views rake task to maintain compatibility with schema.rb.
# The views will be automatically created after running migrations in development.
#
# These views pre-aggregate enrollment and payment statistics to provide
# fast access to commonly requested metrics without expensive real-time
# calculations. The views support both platform-wide and school-specific
# analytics requirements.
#
# Views created:
# - course_enrollment_stats: Per-course enrollment breakdowns by payment method
# - term_enrollment_stats: Per-term enrollment aggregations
# - school_stats: Per-school summary statistics
# - platform_stats: Platform-wide overview metrics
#
# The views distinguish between direct course enrollments and term-based
# enrollments, providing visibility into different enrollment patterns.
class CreateDashboardViews < ActiveRecord::Migration[8.0]
  def up
    # Views are now managed through rake tasks (db:create_views)
    # This ensures compatibility with schema.rb format
    puts "Database views will be created automatically via rake task"
    puts "Run 'rails db:create_views' to manually create views if needed"
  end

  def down
    # Clean up views if they exist
    execute "DROP VIEW IF EXISTS course_enrollment_stats"
    execute "DROP VIEW IF EXISTS school_stats"
    execute "DROP VIEW IF EXISTS term_stats"
    execute "DROP VIEW IF EXISTS platform_stats"
  end
end
