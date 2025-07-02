# Dashboard demo seed data
# This creates some sample data to demonstrate the dashboard functionality

# Create a platform admin user if it doesn't exist
platform_admin = User.find_or_create_by(email: "platform@admin.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = :platform_admin
end

puts "Created platform admin: #{platform_admin.email}"

# Create additional test schools if they don't exist
test_schools = [
  { name: "Demo University", students_count: 15 },
  { name: "Example College", students_count: 8 }
]

test_schools.each do |school_data|
  school = School.find_or_create_by(name: school_data[:name])

  # Create terms for the school
  fall_term = Term.find_or_create_by(name: "Fall 2025", school: school) do |term|
    term.start_date = Date.new(2025, 9, 1)
    term.end_date = Date.new(2025, 12, 15)
    term.price = 1500.00
  end

  spring_term = Term.find_or_create_by(name: "Spring 2026", school: school) do |term|
    term.start_date = Date.new(2026, 1, 15)
    term.end_date = Date.new(2026, 5, 15)
    term.price = 1500.00
  end

  # Create courses for each term
  fall_courses = [
    { name: "Introduction to Computer Science", price: 500.00 },
    { name: "Calculus I", price: 450.00 },
    { name: "Physics I", price: 475.00 }
  ]

  spring_courses = [
    { name: "Data Structures", price: 525.00 },
    { name: "Calculus II", price: 450.00 },
    { name: "Chemistry I", price: 425.00 }
  ]

  fall_courses.each do |course_data|
    Course.find_or_create_by(name: course_data[:name], term: fall_term) do |course|
      course.price = course_data[:price]
    end
  end

  spring_courses.each do |course_data|
    Course.find_or_create_by(name: course_data[:name], term: spring_term) do |course|
      course.price = course_data[:price]
    end
  end

  # Create students for the school
  school_data[:students_count].times do |i|
    user = User.find_or_create_by(email: "student#{i+1}@#{school.name.downcase.gsub(' ', '')}.edu") do |u|
      u.password = "password123"
      u.password_confirmation = "password123"
      u.role = :student
    end

    student = Student.find_or_create_by(user: user, school: school) do |s|
      s.first_name = "Student"
      s.last_name = "#{i+1}"
    end

    # Create some enrollments with different payment methods
    if i < school_data[:students_count] / 2
      # Credit card enrollments for some courses
      course = fall_term.courses.sample

      payment_method = PaymentMethod.find_or_create_by(student: student, method_type: :credit_card) do |pm|
        pm.details = {
          card_number: "4111111111111111",
          expiry_month: "12",
          expiry_year: "2027",
          cvc: "123",
          cardholder_name: "#{student.first_name} #{student.last_name}"
        }.to_json
      end

      purchase = Purchase.find_or_create_by(
        student: student,
        payment_method: payment_method,
        purchaseable: course
      ) do |p|
        p.active = true
      end

      if purchase.persisted? && purchase.enrollments.empty?
        Enrollment.create!(
          student: student,
          purchase: purchase,
          enrollable: course
        )
      end
    else
      # License enrollments for full terms
      license = License.find_or_create_by(school: school, term: fall_term) do |l|
        l.code = License.generate_code(school.name[0..2].upcase, "2025")
        l.status = :redeemed
      end

      payment_method = PaymentMethod.find_or_create_by(student: student, method_type: :license) do |pm|
        pm.license = license
        pm.details = "{}"
      end

      purchase = Purchase.find_or_create_by(
        student: student,
        payment_method: payment_method,
        purchaseable: fall_term
      ) do |p|
        p.active = true
      end

      if purchase.persisted? && purchase.enrollments.empty?
        Enrollment.create!(
          student: student,
          purchase: purchase,
          enrollable: fall_term
        )
      end
    end
  end

  puts "Created school: #{school.name} with #{school.students.count} students"
end

puts "Dashboard demo data created successfully!"
puts ""
puts "To access the dashboard:"
puts "1. Start the server: bin/rails server"
puts "2. Sign in as platform admin: platform@admin.com / password123"
puts "3. Visit: http://localhost:3000/dashboard"
