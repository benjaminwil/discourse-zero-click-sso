# frozen_string_literal: true

require_relative "../oauth2_strategy_override"

# Some of the tests in this file might not look like valuable tests, but I swear
# to you that they were helpful in debugging multiple (bad) redirects as well as
# issues with sessions and cookies that the plugin uses to figure out whether a
# zero-click login is attemptable.
RSpec.describe "Zero-click logins", type: :system do
  before { enable_current_plugin }

  context "when Google is the sole-enabled authentication provider" do
    before do
      OmniAuth.config.test_mode = true

      SiteSetting.enable_google_oauth2_logins = true
      SiteSetting.enable_local_logins = false
      SiteSetting.enable_local_logins_via_email = false
    end

    after do
      OmniAuth.config.test_mode = false
      OmniAuth.config.mock_auth[:google_oauth2] = nil
    end

    context "when the user has no session on Discourse" do
      context "when the user's SSO session does not exist or is not associated with a Discourse user" do
        before do
      	  # OmniAuth in test mode will always succeed to authenticate unless we
      	  # explicitly mock the auth to be a symbol. It would be great to do
      	  # end-to-end integration tests with a real Google OAuth2 client ID and
      	  # secret, but I need to defer doing that work for now. The next best
      	  # thing is to use `:immediate_failed`, which is what I have observed in
      	  # development as the response error for zero-click logins when the user
      	  # does not have a Discourse account associated with their Google
      	  # account.
      	  #
      	  # Note that "immediate_failed" is returned by Google both the following cases:
      	  #
      	  #  - That the user's current Google SSO session exists but is not
      	  #    associated with a Discourse user.
      	  #  - That the user has no current Google SSO session.
          OmniAuth.config.mock_auth[:google_oauth2] = :immediate_failed
        end

        it "allows the user to view the homepage without interruption" do
          visit "/"
          expect(page).to have_current_path "/", ignore_query: true
        end

        it "allows the user to view some other page without interruption" do
          visit "/latest"
          expect(page).to have_current_path "/latest", ignore_query: true
        end
      end

      context "when the user has a Google SSO session that is associated with a Discourse user" do
        fab!(:user)
        let(:fake_provider_uid) { "12345" }

        before do
          UserAssociatedAccount.create!(
            user: user,
            provider_name: "google_oauth2",
            provider_uid: fake_provider_uid,
            info: {email: user.email, name: user.name},
            credentials: {},
            extra: {},
            last_used: Time.now
          )
          OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
            provider: "google_oauth2",
            uid: fake_provider_uid,
            info: OmniAuth::AuthHash::InfoHash.new(
              email: user.email,
              name: user.name
            ),
            extra: {raw_info: {email_verified: true}}
          )
        end

        it "logs in the user with zero clicks required" do
          visit "/"
          expect(page).to have_css(".current-user", visible: true)
        end

        it "allows the user to log out and browse anonymously after a zero-click login" do
          visit "/"
          expect(page).to have_css(".current-user", visible: true)

          click_on "Notifications and account"
          click_on "Profile"
          click_on "Log Out"
          expect(page).not_to have_css(".current-user")

          visit "/latest"
          expect(page).not_to have_css(".current-user")
        end
      end
    end
  end
end
