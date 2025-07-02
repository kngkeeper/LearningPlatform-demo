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
    {
      total_schools: School.count,
      total_students: Student.count,
      total_courses: Course.count,
      total_enrollments: Enrollment.active.count,
      credit_card_enrollments: Enrollment.active.by_payment_type(:credit_card).count,
      license_enrollments: Enrollment.active.by_payment_type(:license).count
    }
  end

  def school_statistics
    School.includes(:students, :terms, :courses).map do |school|
      {
        school: school,
        students_count: school.students.count,
        terms_count: school.terms.count,
        courses_count: school.courses.count,
        active_enrollments: school_active_enrollments_count(school),
        credit_card_enrollments: school_credit_card_enrollments_count(school),
        license_enrollments: school_license_enrollments_count(school)
      }
    end
  end

  def term_statistics(school)
    school.terms.includes(:courses).map do |term|
      enrollments = Enrollment.active.joins(:student)
                              .where(students: { school: school }, enrollable: term)

      {
        term: term,
        courses_count: term.courses.count,
        students_enrolled: enrollments.count,
        credit_card_enrollments: enrollments.by_payment_type(:credit_card).count,
        license_enrollments: enrollments.by_payment_type(:license).count
      }
    end
  end

  def course_statistics(school)
    school.courses.includes(:term).map do |course|
      # Direct course enrollments
      direct_enrollments = Enrollment.active.joins(:student)
                                   .where(students: { school: school }, enrollable: course)

      # Term-based enrollments (students enrolled in the term that contains this course)
      term_enrollments = Enrollment.active.joins(:student)
                                 .where(students: { school: school }, enrollable: course.term)

      total_enrollments = direct_enrollments.count + term_enrollments.count

      {
        course: course,
        students_enrolled: total_enrollments,
        direct_enrollments: direct_enrollments.count,
        term_enrollments: term_enrollments.count,
        credit_card_enrollments: (
          direct_enrollments.by_payment_type(:credit_card).count +
          term_enrollments.by_payment_type(:credit_card).count
        ),
        license_enrollments: (
          direct_enrollments.by_payment_type(:license).count +
          term_enrollments.by_payment_type(:license).count
        )
      }
    end
  end

  def payment_method_statistics(school)
    total_credit_card = Enrollment.active
                                  .joins(:student, purchase: :payment_method)
                                  .where(students: { school: school },
                                         payment_methods: { method_type: :credit_card })
                                  .count

    total_license = Enrollment.active
                              .joins(:student, purchase: :payment_method)
                              .where(students: { school: school },
                                     payment_methods: { method_type: :license })
                              .count

    {
      credit_card: total_credit_card,
      license: total_license,
      total: total_credit_card + total_license
    }
  end

  def school_active_enrollments_count(school)
    Enrollment.active.joins(:student).where(students: { school: school }).count
  end

  def school_credit_card_enrollments_count(school)
    Enrollment.active.joins(:student).where(students: { school: school })
              .by_payment_type(:credit_card).count
  end

  def school_license_enrollments_count(school)
    Enrollment.active.joins(:student).where(students: { school: school })
              .by_payment_type(:license).count
  end
end
