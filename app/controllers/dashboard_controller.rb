class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize :dashboard, :index?
    @dashboard_data = DashboardService.new.platform_analytics
  end

  def school
    authorize :dashboard, :school?
    @school = School.find(params[:school_id])
    @dashboard_data = DashboardService.new.school_analytics(@school)
  end
end
