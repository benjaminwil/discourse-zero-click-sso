# frozen_string_literal: true

require_relative "../oauth2_strategy_override"

# Parts of the core features examples can be skipped like so:
#   it_behaves_like "having working core features", skip_examples: %i[login likes]
#
# List of keywords for skipping examples:
# login, likes, profile, topics, topics:read, topics:reply, topics:create,
# search, search:quick_search, search:full_page
#
# For more details, see https://meta.discourse.org/t/-/361381
RSpec.describe "Core features", type: :system do
  before { enable_current_plugin }

  it_behaves_like "having working core features"

  context "when Google is the sole-enabled authentication provider" do
    before do
      OmniAuth.config.test_mode = true

      SiteSetting.enable_google_oauth2_logins = true
      SiteSetting.enable_local_logins = false
      SiteSetting.enable_local_logins_via_email = false

      # For the purpose of testing that core features continue to work when the
      # plugin is enabled and configured as intended, we will mock Google's
      # "immediate_failed" callback response in a realistic way. This ensures our
      # plugin's `ApplicationController` overrides don't interfere with the stock
      # feature-set.
      OmniAuth.config.mock_auth[:google_oauth2] = :immediate_failed
    end

    after do
      OmniAuth.config.test_mode = false
      OmniAuth.config.mock_auth[:google_oauth2] = nil
    end

    context "when the user has a session on Discourse" do
      before do
        visit "/"
      end

      it_behaves_like "having working core features", skip_examples: [:login]
    end

    context "when the user does not have a session on Discourse" do
      it_behaves_like "having working core features", skip_examples: [:login]
    end
  end
end
