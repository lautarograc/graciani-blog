module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :require_admin

    private
      def require_admin
        render "admin/base/sign_in", status: :unauthorized, layout: "application" unless signed_in?
      end
  end
end
