# frozen_string_literal: true

# name: discourse-zero-click-sso
# about: For fresh forum sessions, attempt to log users into Discourse using an existing SSO session.
# meta_topic_id: TODO
# version: 0.0.1
# authors: benjamin wil
# url: https://github.com/benjaminwil/discourse-zero-click-sso
# required_version: 2.7.0

enabled_site_setting :zero_click_sso_enabled

module ::ZeroClickSso
  PLUGIN_NAME = "discourse-zero-click-sso"

  ATTEMPTED_SESSION_KEY = :skip_zero_click_sso_attempts

  AUTH_ROUTES_PREFIX = "/auth/"
  IGNORED_ROUTES = ["/login", "/signup"]

  def self.attemptable?
    return false if SiteSetting.enable_local_logins?
    return false unless Discourse.enabled_authenticators.one?
    true
  end
end

require_relative "lib/zero_click_sso/application_controller_override"
require_relative "lib/zero_click_sso/google_oauth2_authenticator_override"
require_relative "lib/zero_click_sso/engine"

after_initialize do
  ApplicationController.prepend(ZeroClickSso::ApplicationControllerOverride)
  Auth::GoogleOAuth2Authenticator.prepend(ZeroClickSso::GoogleOAuth2AuthenticatorOverride)

  # Handle the additional OAuth2 error types required for good zero-click login
  # user experience by extending the Discourse application's failure handler.
  original_omniauth_failure_handler = OmniAuth.config.on_failure

  OmniAuth.config.on_failure = Proc.new do |env|
    exception = env["omniauth.error"]

    # If the error is not OAuth2 callback-related, we can continue using the
    # application's failure handler.
    unless exception.is_a?(OmniAuth::Strategies::OAuth2::CallbackError)
      next original_omniauth_failure_handler.call(env)
    end

    error_code = exception.message.to_sym

    # "immediate_failed" is Google's error code in scenarios where no user could
    # be automatically selected without prompting the OAuth login consent flow.
    # This error code should only be returned if the application requested OAuth2
    # authentication with a `prompt=none` parameter value.
    #
    #   Docs: https://developers.google.com/identity/sign-in/web/reference
    #
    # In the context of this plugin, "immediate_failed" indicates that a
    # zero-click login attempt failed. It likely failed because:
    #
    # - The browser has no current Google SSO session.
    # - The browser's Google SSO session does not map to any existing  user for
    #   the current Discourse instance.
    #
    # So we want to suppress any error message and let the user continue
    # browsing at their destination URL.
    if error_code == :immediate_failed
      request = ActionDispatch::Request.new(env)
      origin = request.cookies["destination_url"] || "/"

      request.session[ZeroClickSso::ATTEMPTED_SESSION_KEY] = "true"

      next [302, {"Location" => origin, "Content-Type" => "text/html"}, []]
    else
      OmniAuth::FailureEndpoint.call(env)
    end
  end
end
