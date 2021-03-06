# frozen_string_literal: true
require 'net/http'
require 'net/https'
require 'uri'

class Auth::RegistrationsController < Devise::RegistrationsController
  layout :determine_layout

  before_action :set_invite, only: [:new, :create]
  before_action :check_enabled_registrations, only: [:new, :create]
  before_action :configure_sign_up_params, only: [:create]
  before_action :set_sessions, only: [:edit, :update]
  before_action :set_instance_presenter, only: [:new, :create, :update]
  before_action :set_body_classes, only: [:new, :create, :edit, :update]
  before_action :set_cache_headers, only: [:edit, :update]

  def new
    super(&:build_invite_request)
  end

  def destroy
    not_found
  end

  protected

  def update_resource(resource, params)
    params[:password] = nil if Devise.pam_authentication && resource.encrypted_password.blank?
    super
  end

  def build_resource(hash = nil)
    super(hash)

    resource.locale             = I18n.locale
    resource.invite_code        = params[:invite_code] if resource.invite_code.blank?
    resource.agreement          = true
    resource.current_sign_in_ip = request.remote_ip

    resource.build_account if resource.account.nil?
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up) do |u|
      u.permit({ account_attributes: [:username], invite_request_attributes: [:text] }, :email, :password, :password_confirmation, :invite_code)
    end
  end

  def after_sign_up_path_for(_resource)
    new_user_session_path
  end

  def after_sign_in_path_for(_resource)
    set_invite

    if @invite&.autofollow?
      short_account_path(@invite.user.account)
    else
      super
    end
  end

  def after_inactive_sign_up_path_for(_resource)
    integrate_tracking_leads
    new_user_session_path
  end

  def after_update_path_for(_resource)
    edit_user_registration_path
  end

  def check_enabled_registrations
    redirect_to root_path if single_user_mode? || !allowed_registrations?
  end

  def allowed_registrations?
    Setting.registrations_mode != 'none' || @invite&.valid_for_use?
  end

  def invite_code
    if params[:user]
      params[:user][:invite_code]
    else
      params[:invite_code]
    end
  end

  private

  def set_instance_presenter
    @instance_presenter = InstancePresenter.new
  end

  def set_body_classes
    @body_classes = %w(edit update).include?(action_name) ? 'admin' : ''
  end

  def set_invite
    invite = invite_code.present? ? Invite.find_by(code: invite_code) : nil
    @invite = invite&.valid_for_use? ? invite : nil
  end

  def determine_layout
    %w(edit update).include?(action_name) ? 'admin' : 'auth'
  end

  def set_sessions
    @sessions = current_user.session_activations
  end

  def set_cache_headers
    response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
  end

  def integrate_tracking_leads
    tid = cookies[:_fprom_track]

    if tid
      uri = URI('https://firstpromoter.com/api/v1/track/signup')

      req = Net::HTTP::Post.new(uri, {
        'Content-Type' => 'application/json',
        'x-api-key' => ENV['PROMOTER_API_KEY'],
      })

      req.set_form_data('wid' => ENV['PROMOTER_WID'], 'email'=> @user[:email], 'event_id' => @user[:id],'tid' => tid)
      res = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
        http.request(req)
      end
    end
  end
end
