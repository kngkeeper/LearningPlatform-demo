# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create platform admin user
admin_user = User.find_or_create_by!(email: "admin@learningplatform.com") do |user|
  user.role = :platform_admin
  user.password = "password123"
  user.password_confirmation = "password123"
end

puts "Created platform admin user: #{admin_user.email}"

# Create sample schools for testing
schools = [
  "Cedar Elementary School",
  "Dover High School",
  "Mountain View Middle School",
  "Oakwood Academy",
  "Sunshine Learning Center"
]

schools.each do |school_name|
  School.find_or_create_by!(name: school_name)
end

puts "Created #{School.count} schools"

# Create terms for each school
term_data = [
  { name: "Fall 2025", start_date: Date.new(2025, 9, 1), end_date: Date.new(2025, 12, 15), price: 499.99 },
  { name: "Spring 2026", start_date: Date.new(2026, 1, 15), end_date: Date.new(2026, 5, 30), price: 549.99 },
  { name: "Summer 2026", start_date: Date.new(2026, 6, 1), end_date: Date.new(2026, 8, 15), price: 399.99 },
  { name: "Fall 2026", start_date: Date.new(2026, 9, 1), end_date: Date.new(2026, 12, 15), price: 499.99 }
]

School.all.each do |school|
  term_data.each do |term_info|
    Term.find_or_create_by!(
      name: term_info[:name],
      school: school
    ) do |term|
      term.start_date = term_info[:start_date]
      term.end_date = term_info[:end_date]
      term.price = term_info[:price]
    end
  end
end

puts "Created #{Term.count} terms across all schools"

# Create courses for each term
course_subjects = [
  "Mathematics", "English Language Arts", "Science", "Social Studies",
  "Art", "Music", "Physical Education", "Computer Science",
  "Foreign Language", "Health Education"
]

course_levels = [ "Beginner", "Intermediate", "Advanced" ]

Term.all.each do |term|
  # Skip if this term already has courses
  next if term.courses.exists?

  # Create 5-8 courses per term
  courses_per_term = rand(5..8)
  selected_subjects = course_subjects.sample(courses_per_term)

  selected_subjects.each do |subject|
    level = course_levels.sample
    course_name = "#{subject} - #{level}"
    # Assign a price based on level
    course_price = case level
    when "Beginner"
      rand(49.99..99.99).round(2)
    when "Intermediate"
      rand(99.99..149.99).round(2)
    when "Advanced"
      rand(149.99..199.99).round(2)
    end

    Course.find_or_create_by!(
      name: course_name,
      term: term
    ) do |course|
      course.content = "This is the course content for #{course_name}."
      course.price = course_price
    end
  end
end

puts "Created #{Course.count} courses across all terms"

# Create students for each school
School.all.each do |school|
  # Only create students if this school doesn't have any yet
  next if school.students.exists?

  5.times do |i|
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    # Use deterministic email to avoid unique constraint issues
    # Sanitize names to prevent invalid email characters from Faker
    clean_first_name = first_name.downcase.gsub(/[^a-z0-9]/, "")
    clean_last_name = last_name.downcase.gsub(/[^a-z0-9]/, "")
    email = "#{clean_first_name}.#{clean_last_name}.#{school.id}.#{i}@example.com"

    User.find_or_create_by!(email: email) do |user|
      user.role = :student
      user.password = "password123"
      user.password_confirmation = "password123"
      user.first_name = first_name
      user.last_name = last_name
      user.school_id = school.id

      # Build the associated student record
      user.build_student(
        school: school,
        first_name: first_name,
        last_name: last_name
      )
    end
  end
end

puts "Created #{Student.count} students"

# Create licenses for terms
Term.all.each do |term|
  # Skip if this term already has licenses
  next if term.licenses.exists?

  5.times do |i|
    # Generate a unique code by including the index
    code = "#{License.generate_code(term.school.name.parameterize.upcase, term.start_date.year)}-#{i+1}"

    License.find_or_create_by!(
      school: term.school,
      term: term,
      code: code
    )
  end
end

puts "Created #{License.count} licenses"

# Enroll students
Student.all.each do |student|
  # Skip if student already has enrollments
  next if student.enrollments.exists?

  # Enroll in one term via license
  term_to_enroll = student.school.terms.sample
  license = term_to_enroll.licenses.where(status: :active).first
  if license
    # Check if payment method already exists for this student and license
    payment_method = PaymentMethod.find_or_create_by!(
      student: student,
      method_type: :license,
      license: license
    )

    # Check if purchase already exists
    purchase = Purchase.find_or_create_by!(
      student: student,
      payment_method: payment_method,
      purchaseable: term_to_enroll
    )

    # Only process if not already processed
    purchase.process!
    license.update(status: :redeemed) if license.status == 'active'
  end

  # Enroll in 1-2 individual courses via credit card
  available_courses = student.school.courses.where.not(term: term_to_enroll)
  courses_to_enroll = available_courses.sample([ available_courses.count, 2 ].min)

  courses_to_enroll.each do |course|
    # Check if already enrolled in this course
    next if student.enrollments.where(enrollable: course).exists?

    payment_method = PaymentMethod.find_or_create_by!(
      student: student,
      method_type: :credit_card
    ) do |pm|
      pm.details = {
        cardholder_name: student.full_name,
        card_number: Faker::Finance.credit_card,
        expiry_month: Faker::Number.between(from: 1, to: 12),
        expiry_year: Date.current.year + Faker::Number.between(from: 1, to: 5),
        cvv: Faker::Number.number(digits: 3)
      }.to_json
    end

    purchase = Purchase.find_or_create_by!(
      student: student,
      payment_method: payment_method,
      purchaseable: course
    )
    purchase.process!
  end
end

puts "Enrolled students in courses and terms"

# Generate and display sample license codes for each school
puts "\n=== Sample License Codes for Testing ==="
School.all.each do |school|
  # Get the first term for this school
  first_term = school.terms.order(:start_date).first
  if first_term
    # Find an active license for this term, or create one if none exists
    sample_license = first_term.licenses.where(status: :active).first
    if sample_license
      puts "#{school.name}: #{sample_license.code}"
    else
      # Create a sample license if none exists
      sample_code = "#{License.generate_code(school.name.parameterize.upcase, first_term.start_date.year)}-SAMPLE"
      sample_license = License.find_or_create_by!(
        school: school,
        term: first_term,
        code: sample_code
      )
      puts "#{school.name}: #{sample_license.code}"
    end
  end
end

# Summary
puts "\n=== Seeding Summary ==="
puts "Platform Admin Users: #{User.platform_admin.count}"
puts "Schools: #{School.count}"
puts "Terms: #{Term.count}"
puts "Courses: #{Course.count}"
puts "Students: #{Student.count}"
puts "Enrollments: #{Enrollment.count}"
puts "Purchases: #{Purchase.count}"
puts "Licenses: #{License.count}"
puts "\nAdmin login credentials:"
puts "Email: admin@learningplatform.com"
puts "Password: password123"
