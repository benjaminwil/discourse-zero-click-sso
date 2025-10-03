# frozen_string_literal: true
module ZeroClickSso
  # Overrides the Google OAuth2 middleware registration built into Discourse.
  #
  # In an ideal world, we would be able to call `super` to get the built-in
  # functionality and then only add the additional functional required for
  # our plugin, but the lambda makes this more difficult, so I've chosen to
  # override the method entirely, for clarity in the plugin source.
  #
  # See the inline comments for details about the plugin functionality.
  module GoogleOAuth2AuthenticatorOverride
    def register_middleware(omniauth)
      options = {
        setup:
          lambda do |env|
            opts = env["omniauth.strategy"].options
            opts[:client_id] = SiteSetting.google_oauth2_client_id
            opts[:client_secret] = SiteSetting.google_oauth2_client_secret

            if (google_oauth2_hd = SiteSetting.google_oauth2_hd).present?
              opts[:hd] = google_oauth2_hd
            end

            if (google_oauth2_prompt = SiteSetting.google_oauth2_prompt).present?
              opts[:prompt] = google_oauth2_prompt.gsub("|", " ")
            end
            opts[:client_options][:connection_build] = lambda do |builder|
              if SiteSetting.google_oauth2_verbose_logging
                builder.response :logger,
                                 Rails.logger,
                                 { bodies: true, formatter: Auth::OauthFaradayFormatter }
              end
              builder.request :url_encoded
              builder.adapter FinalDestination::FaradayAdapter
            end
            opts[:skip_jwt] = true

            # The following conditions have been added for the plugin. We want
            # to inject the OpenID Connect `prompt` parameter with a value of
            # `none` to allow for silent, zero-click logins from any route the
            # user visits (other than `/login` and `/signup`).
            request = ActionDispatch::Request.new(env)

            is_authorization_endpoint =
              env["PATH_INFO"] == env["omniauth.strategy"].request_path
            is_zero_click_attempt = request.params["zero-click"] == "yes"

            if ZeroClickSso.attemptable? && (is_authorization_endpoint && is_zero_click_attempt)
              opts[:prompt] = "none"
            else
              opts[:prompt] = google_oauth2_prompt.gsub("|", " ")
            end
          end,
      }
      omniauth.provider :google_oauth2, options
    end
  end
end
