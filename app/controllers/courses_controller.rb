class CoursesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_student

  def index
    @courses = available_courses_for_enrollment
  end

  private

  def available_courses_for_enrollment
    return Course.none unless current_user.student

    student = current_user.student
    Course.available_for_enrollment(student.school)
  end

  def ensure_student
    redirect_to new_user_session_path unless current_user&.student?
  end
end
