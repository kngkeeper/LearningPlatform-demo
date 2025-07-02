class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pundit::Authorization

  # Redirect to appropriate page after sign in
  def after_sign_in_path_for(resource)
    if resource.platform_admin?
      dashboard_path
    else
      root_path
    end
  end
end
