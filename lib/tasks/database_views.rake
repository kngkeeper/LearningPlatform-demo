namespace :db do
  desc "Create database views for dashboard analytics"
  task create_views: :environment do
    puts "Creating database views..."

    # Create the views using raw SQL
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE OR REPLACE VIEW course_enrollment_stats AS
      SELECT
        c.id as course_id,
        t.school_id,
        c.term_id,
        COALESCE(direct_stats.direct_enrollments, 0) as direct_enrollments,
        COALESCE(direct_stats.direct_credit_card, 0) as direct_credit_card,
        COALESCE(direct_stats.direct_license, 0) as direct_license,
        COALESCE(term_stats.term_enrollments, 0) as term_enrollments,
        COALESCE(term_stats.term_credit_card, 0) as term_credit_card,
        COALESCE(term_stats.term_license, 0) as term_license,
        COALESCE(direct_stats.direct_enrollments, 0) + COALESCE(term_stats.term_enrollments, 0) as students_enrolled,
        COALESCE(direct_stats.direct_credit_card, 0) + COALESCE(term_stats.term_credit_card, 0) as credit_card_enrollments,
        COALESCE(direct_stats.direct_license, 0) + COALESCE(term_stats.term_license, 0) as license_enrollments
      FROM courses c
      JOIN terms t ON t.id = c.term_id
      LEFT JOIN (
        SELECT
          c.id as course_id,
          COUNT(DISTINCT e.id) as direct_enrollments,
          COUNT(DISTINCT CASE WHEN pm.method_type = 0 THEN e.id END) as direct_credit_card,
          COUNT(DISTINCT CASE WHEN pm.method_type = 1 THEN e.id END) as direct_license
        FROM courses c
        LEFT JOIN enrollments e ON e.enrollable_type = 'Course' AND e.enrollable_id = c.id
        LEFT JOIN students s ON s.id = e.student_id
        LEFT JOIN purchases p ON p.id = e.purchase_id AND p.active = true
        LEFT JOIN payment_methods pm ON pm.id = p.payment_method_id
        GROUP BY c.id
      ) direct_stats ON direct_stats.course_id = c.id
      LEFT JOIN (
        SELECT
          c.id as course_id,
          COUNT(DISTINCT e.id) as term_enrollments,
          COUNT(DISTINCT CASE WHEN pm.method_type = 0 THEN e.id END) as term_credit_card,
          COUNT(DISTINCT CASE WHEN pm.method_type = 1 THEN e.id END) as term_license
        FROM courses c
        LEFT JOIN enrollments e ON e.enrollable_type = 'Term' AND e.enrollable_id = c.term_id
        LEFT JOIN students s ON s.id = e.student_id
        LEFT JOIN purchases p ON p.id = e.purchase_id AND p.active = true
        LEFT JOIN payment_methods pm ON pm.id = p.payment_method_id
        GROUP BY c.id
      ) term_stats ON term_stats.course_id = c.id
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE OR REPLACE VIEW school_stats AS
      SELECT
        s.id as school_id,
        COUNT(DISTINCT st.id) as students_count,
        COUNT(DISTINCT t.id) as terms_count,
        COUNT(DISTINCT c.id) as courses_count,
        COUNT(DISTINCT e.id) as active_enrollments,
        COUNT(DISTINCT CASE WHEN pm.method_type = 0 THEN e.id END) as credit_card_enrollments,
        COUNT(DISTINCT CASE WHEN pm.method_type = 1 THEN e.id END) as license_enrollments
      FROM schools s
      LEFT JOIN students st ON st.school_id = s.id
      LEFT JOIN terms t ON t.school_id = s.id
      LEFT JOIN courses c ON c.term_id = t.id
      LEFT JOIN enrollments e ON e.student_id = st.id
      LEFT JOIN purchases p ON p.id = e.purchase_id AND p.active = true
      LEFT JOIN payment_methods pm ON pm.id = p.payment_method_id
      GROUP BY s.id
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE OR REPLACE VIEW term_stats AS
      SELECT
        t.id as term_id,
        t.school_id,
        COUNT(DISTINCT c.id) as courses_count,
        COUNT(DISTINCT e.id) as students_enrolled,
        COUNT(DISTINCT CASE WHEN pm.method_type = 0 THEN e.id END) as credit_card_enrollments,
        COUNT(DISTINCT CASE WHEN pm.method_type = 1 THEN e.id END) as license_enrollments
      FROM terms t
      LEFT JOIN courses c ON c.term_id = t.id
      LEFT JOIN enrollments e ON e.enrollable_type = 'Term' AND e.enrollable_id = t.id
      LEFT JOIN students s ON s.id = e.student_id AND s.school_id = t.school_id
      LEFT JOIN purchases p ON p.id = e.purchase_id AND p.active = true
      LEFT JOIN payment_methods pm ON pm.id = p.payment_method_id
      GROUP BY t.id, t.school_id
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE OR REPLACE VIEW platform_stats AS
      SELECT
        (SELECT COUNT(*) FROM schools) as total_schools,
        (SELECT COUNT(*) FROM students) as total_students,
        (SELECT COUNT(*) FROM courses) as total_courses,
        COUNT(DISTINCT e.id) as total_enrollments,
        COUNT(DISTINCT CASE WHEN pm.method_type = 0 THEN e.id END) as credit_card_enrollments,
        COUNT(DISTINCT CASE WHEN pm.method_type = 1 THEN e.id END) as license_enrollments
      FROM enrollments e
      JOIN purchases p ON p.id = e.purchase_id AND p.active = true
      JOIN payment_methods pm ON pm.id = p.payment_method_id
      JOIN students s ON s.id = e.student_id
    SQL

    puts "Database views created successfully!"
  end

  desc "Drop database views"
  task drop_views: :environment do
    puts "Dropping database views..."

    ActiveRecord::Base.connection.execute "DROP VIEW IF EXISTS course_enrollment_stats"
    ActiveRecord::Base.connection.execute "DROP VIEW IF EXISTS school_stats"
    ActiveRecord::Base.connection.execute "DROP VIEW IF EXISTS term_stats"
    ActiveRecord::Base.connection.execute "DROP VIEW IF EXISTS platform_stats"

    puts "Database views dropped successfully!"
  end

  desc "Reset database views (drop and recreate)"
  task reset_views: [ :drop_views, :create_views ]

  # Hook into the standard Rails database setup tasks
  task setup: :create_views
  task reset: :create_views
end

# Also create views after migrations in development
Rake::Task["db:migrate"].enhance do
  Rake::Task["db:create_views"].invoke if Rails.env.development?
end
