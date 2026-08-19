class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    login = auth&.info&.nickname

    if login.present? && login.casecmp?(allowed_github_login)
      session[:github_login] = login
      redirect_to admin_posts_path, notice: "Signed in as #{login}."
    else
      redirect_to root_path, alert: "That GitHub account isn't allowed to sign in here."
    end
  end

  def failure
    redirect_to root_path, alert: "GitHub sign-in failed: #{params[:message]}"
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out."
  end

  private
    def allowed_github_login
      Rails.application.credentials.dig(:github, :allowed_login) || ENV["ALLOWED_GITHUB_LOGIN"]
    end
end
