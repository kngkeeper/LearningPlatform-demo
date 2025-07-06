# Provides aggregated analytics and reporting data for the learning platform.
#
# This service centralizes complex queries and calculations used by dashboard views,
# supporting both platform-wide analytics for administrators and school-specific
# reporting for individual institutions.
#
# The service leverages database views (Views::PlatformStat, Views::SchoolStat, etc.)
# for optimized performance on frequently accessed analytics data.
class DashboardService
  # Returns platform-wide analytics including school statistics and overview metrics
  def platform_analytics
    {
      schools: school_statistics,
      overview: platform_overview
    }
  end

  # Returns detailed analytics for a specific school including enrollment and payment breakdowns
  def school_analytics(school)
    {
      school: school,
      terms: term_statistics(school),
      courses: course_statistics(school),
      payment_methods: payment_method_statistics(school)
    }
  end

  private

  # Aggregates platform-wide statistics using optimized database views
  def platform_overview
    # Use the platform_stats view for a single query
    stats = Views::PlatformStat.current
    return default_platform_stats unless stats

    {
      total_schools: stats.total_schools,
      total_students: stats.total_students,
      total_courses: stats.total_courses,
      total_enrollments: stats.total_enrollments,
      credit_card_enrollments: stats.credit_card_enrollments,
      license_enrollments: stats.license_enrollments
    }
  end

  # Generates per-school statistics using pre-aggregated database views
  def school_statistics
    # Use the school_stats view for optimized single query per school
    Views::SchoolStat.includes(:school).map do |school_stat|
      {
        school: school_stat.school,
        students_count: school_stat.students_count,
        terms_count: school_stat.terms_count,
        courses_count: school_stat.courses_count,
        active_enrollments: school_stat.active_enrollments,
        credit_card_enrollments: school_stat.credit_card_enrollments,
        license_enrollments: school_stat.license_enrollments
      }
    end
  end

  def term_statistics(school)
    Views::TermStat.for_school(school).includes(:term).map do |term_stat|
      {
        term: term_stat.term,
        courses_count: term_stat.courses_count,
        students_enrolled: term_stat.students_enrolled,
        credit_card_enrollments: term_stat.credit_card_enrollments,
        license_enrollments: term_stat.license_enrollments
      }
    end
  end

  def course_statistics(school)
    Views::CourseEnrollmentStat.for_school(school).includes(:course).map do |course_stat|
      {
        course: course_stat.course,
        students_enrolled: course_stat.students_enrolled,
        direct_enrollments: course_stat.direct_enrollments,
        term_enrollments: course_stat.term_enrollments,
        credit_card_enrollments: course_stat.credit_card_enrollments,
        license_enrollments: course_stat.license_enrollments
      }
    end
  end

  # Aggregates payment method usage statistics for the school
  def payment_method_statistics(school)
    credit_card_count = Enrollment.for_school(school).by_payment_type(:credit_card).count
    license_count = Enrollment.for_school(school).by_payment_type(:license).count

    {
      credit_card: credit_card_count,
      license: license_count,
      total: credit_card_count + license_count
    }
  end

  # Fallback statistics when database views are not available
  def default_platform_stats
    {
      total_schools: 0,
      total_students: 0,
      total_courses: 0,
      total_enrollments: 0,
      credit_card_enrollments: 0,
      license_enrollments: 0
    }
  end
end
