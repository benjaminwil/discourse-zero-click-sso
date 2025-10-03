# frozen_string_literal: true
module ZeroClickSso
  module ApplicationControllerOverride
    extend ActiveSupport::Concern

    prepended do
      before_action :attempt_zero_click_sso_login

      after_action :mark_as_zero_click_sso_attempted
    end

    private

    def attempt_zero_click_sso_login
      return unless request.format.html? && !is_api?
      return if session[ZeroClickSso::ATTEMPTED_SESSION_KEY]

      return unless ZeroClickSso.attemptable?
      return if ZeroClickSso::IGNORED_ROUTES.include?(request.path)
      return if request.path.start_with?(::ZeroClickSso::AUTH_ROUTES_PREFIX)

      cookies[:destination_url] = destination_url
      redirect_to path("/auth/#{Discourse.enabled_authenticators.first.name}?zero-click=yes")
    end

    def mark_as_zero_click_sso_attempted
      session[ZeroClickSso::ATTEMPTED_SESSION_KEY]||= "true"
    end
  end
end
