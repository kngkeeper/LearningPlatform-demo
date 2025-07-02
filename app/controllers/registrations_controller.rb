class RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]

  # GET /resource/sign_up
  def new
    super do |resource|
      @schools = School.order(:name)
    end
  end

  # POST /resource
  def create
    build_resource(sign_up_params)

    resource.role = :student # Set role to student by default

    resource.save
    yield resource if block_given?
    if resource.persisted?
      # Create the associated student record
      create_student_record(resource)

      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_up!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      @schools = School.order(:name)
      respond_with resource
    end
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :school_id ])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name ])
  end

  private

  def create_student_record(user)
    return unless user.persisted? && params[:user][:school_id].present?

    Student.create!(
      user: user,
      school_id: params[:user][:school_id],
      first_name: params[:user][:first_name],
      last_name: params[:user][:last_name]
    )
  end

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :school_id)
  end
end
