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
  { name: "Fall 2025", start_date: Date.new(2025, 9, 1), end_date: Date.new(2025, 12, 15) },
  { name: "Spring 2026", start_date: Date.new(2026, 1, 15), end_date: Date.new(2026, 5, 30) },
  { name: "Summer 2026", start_date: Date.new(2026, 6, 1), end_date: Date.new(2026, 8, 15) },
  { name: "Fall 2026", start_date: Date.new(2026, 9, 1), end_date: Date.new(2026, 12, 15) }
]

School.all.each do |school|
  term_data.each do |term_info|
    Term.find_or_create_by!(
      name: term_info[:name],
      school: school
    ) do |term|
      term.start_date = term_info[:start_date]
      term.end_date = term_info[:end_date]
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
  # Create 5-8 courses per term
  courses_per_term = rand(5..8)
  selected_subjects = course_subjects.sample(courses_per_term)

  selected_subjects.each do |subject|
    level = course_levels.sample
    course_name = "#{subject} - #{level}"

    Course.find_or_create_by!(
      name: course_name,
      term: term
    )
  end
end

puts "Created #{Course.count} courses across all terms"

# Summary
puts "\n=== Seeding Summary ==="
puts "Platform Admin Users: #{User.platform_admin.count}"
puts "Schools: #{School.count}"
puts "Terms: #{Term.count}"
puts "Courses: #{Course.count}"
puts "\nAdmin login credentials:"
puts "Email: admin@learningplatform.com"
puts "Password: password123"
