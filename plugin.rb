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
end

require_relative "lib/zero_click_sso/engine"

after_initialize do
  # Code which should run after Rails has finished booting
end
