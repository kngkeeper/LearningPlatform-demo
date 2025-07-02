class DashboardService
  def platform_analytics
    {
      schools: school_statistics,
      overview: platform_overview
    }
  end

  def school_analytics(school)
    {
      school: school,
      terms: term_statistics(school),
      courses: course_statistics(school),
      payment_methods: payment_method_statistics(school)
    }
  end

  private

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
    # Use the term_stats view for simplified querying
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
    # Use the course_enrollment_stats view to replace the complex 8-JOIN query
    Views::CourseEnrollmentStat.for_school(school).includes(:course).map do |course_stat|
      {
        course: course_stat.course,
        students_enrolled: course_stat.total_enrollments,
        direct_enrollments: course_stat.direct_enrollments,
        term_enrollments: course_stat.term_enrollments,
        credit_card_enrollments: course_stat.total_credit_card,
        license_enrollments: course_stat.total_license
      }
    end
  end

  def payment_method_statistics(school)
    payment_stats = Enrollment.active
                              .for_school(school)
                              .joins(purchase: :payment_method)
                              .group("payment_methods.method_type")
                              .count

    credit_card_count = payment_stats["credit_card"] || 0
    license_count = payment_stats["license"] || 0

    {
      credit_card: credit_card_count,
      license: license_count,
      total: credit_card_count + license_count
    }
  end
end
