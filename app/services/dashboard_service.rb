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
    # Single query to get all stats at once
    enrollment_stats = Enrollment.active
                                 .joins(:student, purchase: :payment_method)
                                 .group("payment_methods.method_type")
                                 .count

    {
      total_schools: School.count,
      total_students: Student.count,
      total_courses: Course.count,
      total_enrollments: enrollment_stats.values.sum,
      credit_card_enrollments: enrollment_stats["credit_card"] || 0,
      license_enrollments: enrollment_stats["license"] || 0
    }
  end

  def school_statistics
    # Optimized query with single database call
    School.joins(:students)
          .joins("LEFT JOIN enrollments ON enrollments.student_id = students.id")
          .joins("LEFT JOIN purchases ON purchases.id = enrollments.purchase_id AND purchases.active = true")
          .joins("LEFT JOIN payment_methods ON payment_methods.id = purchases.payment_method_id")
          .group("schools.id")
          .select(
            "schools.*",
            "COUNT(DISTINCT students.id) as students_count",
            "COUNT(DISTINCT enrollments.id) as active_enrollments",
            "COUNT(DISTINCT CASE WHEN payment_methods.method_type = 0 THEN enrollments.id END) as credit_card_enrollments",
            "COUNT(DISTINCT CASE WHEN payment_methods.method_type = 1 THEN enrollments.id END) as license_enrollments"
          )
          .includes(:terms, :courses)
          .map do |school|
            {
              school: school,
              students_count: school.students_count,
              terms_count: school.terms.size,
              courses_count: school.courses.size,
              active_enrollments: school.active_enrollments,
              credit_card_enrollments: school.credit_card_enrollments,
              license_enrollments: school.license_enrollments
            }
          end
  end

  def term_statistics(school)
    # Single query to get all term statistics at once
    term_data = school.terms
                      .joins("LEFT JOIN enrollments ON enrollments.enrollable_type = 'Term' AND enrollments.enrollable_id = terms.id")
                      .joins("LEFT JOIN students ON students.id = enrollments.student_id AND students.school_id = #{school.id}")
                      .joins("LEFT JOIN purchases ON purchases.id = enrollments.purchase_id AND purchases.active = true")
                      .joins("LEFT JOIN payment_methods ON payment_methods.id = purchases.payment_method_id")
                      .group("terms.id")
                      .select(
                        "terms.*",
                        "COUNT(DISTINCT enrollments.id) as students_enrolled",
                        "COUNT(DISTINCT CASE WHEN payment_methods.method_type = 0 THEN enrollments.id END) as credit_card_enrollments",
                        "COUNT(DISTINCT CASE WHEN payment_methods.method_type = 1 THEN enrollments.id END) as license_enrollments"
                      )
                      .includes(:courses)

    term_data.map do |term|
      {
        term: term,
        courses_count: term.courses.size,
        students_enrolled: term.students_enrolled,
        credit_card_enrollments: term.credit_card_enrollments,
        license_enrollments: term.license_enrollments
      }
    end
  end

  def course_statistics(school)
    # Get all course enrollment data in a single optimized query
    course_enrollments = school.courses
                               .joins("LEFT JOIN enrollments direct_enrollments ON direct_enrollments.enrollable_type = 'Course' AND direct_enrollments.enrollable_id = courses.id")
                               .joins("LEFT JOIN students direct_students ON direct_students.id = direct_enrollments.student_id AND direct_students.school_id = #{school.id}")
                               .joins("LEFT JOIN purchases direct_purchases ON direct_purchases.id = direct_enrollments.purchase_id AND direct_purchases.active = true")
                               .joins("LEFT JOIN payment_methods direct_payment_methods ON direct_payment_methods.id = direct_purchases.payment_method_id")
                               .joins("LEFT JOIN enrollments term_enrollments ON term_enrollments.enrollable_type = 'Term' AND term_enrollments.enrollable_id = courses.term_id")
                               .joins("LEFT JOIN students term_students ON term_students.id = term_enrollments.student_id AND term_students.school_id = #{school.id}")
                               .joins("LEFT JOIN purchases term_purchases ON term_purchases.id = term_enrollments.purchase_id AND term_purchases.active = true")
                               .joins("LEFT JOIN payment_methods term_payment_methods ON term_payment_methods.id = term_purchases.payment_method_id")
                               .group("courses.id")
                               .select(
                                 "courses.*",
                                 "COUNT(DISTINCT direct_enrollments.id) as direct_enrollments_count",
                                 "COUNT(DISTINCT term_enrollments.id) as term_enrollments_count",
                                 "COUNT(DISTINCT CASE WHEN direct_payment_methods.method_type = 0 THEN direct_enrollments.id END) as direct_credit_card",
                                 "COUNT(DISTINCT CASE WHEN direct_payment_methods.method_type = 1 THEN direct_enrollments.id END) as direct_license",
                                 "COUNT(DISTINCT CASE WHEN term_payment_methods.method_type = 0 THEN term_enrollments.id END) as term_credit_card",
                                 "COUNT(DISTINCT CASE WHEN term_payment_methods.method_type = 1 THEN term_enrollments.id END) as term_license"
                               )
                               .includes(:term)

    course_enrollments.map do |course|
      total_enrollments = course.direct_enrollments_count + course.term_enrollments_count
      total_credit_card = course.direct_credit_card + course.term_credit_card
      total_license = course.direct_license + course.term_license

      {
        course: course,
        students_enrolled: total_enrollments,
        direct_enrollments: course.direct_enrollments_count,
        term_enrollments: course.term_enrollments_count,
        credit_card_enrollments: total_credit_card,
        license_enrollments: total_license
      }
    end
  end

  def payment_method_statistics(school)
    # Single query to get payment method statistics
    payment_stats = Enrollment.active
                              .joins(:student, purchase: :payment_method)
                              .where(students: { school: school })
                              .group("payment_methods.method_type")
                              .count

    credit_card_count = payment_stats[0] || 0  # method_type enum: credit_card = 0
    license_count = payment_stats[1] || 0      # method_type enum: license = 1

    {
      credit_card: credit_card_count,
      license: license_count,
      total: credit_card_count + license_count
    }
  end
end
