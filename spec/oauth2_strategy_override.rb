# frozen_string_literal: true
# In order to simulate zero-click login failures in a realistic way so that the
# Discourse core features shared examples can be run successfully, I needed to
# change the behaviour of OmniAuth's `OmniAuth::Strategy#mock_callback_call`.
#
# It could be great to attempt upstreaming this change to OmniAuth so that
# developers can use OmniAuth's test mode for a larger set of tests.
module OmniAuth::Strategies::OAuth2TestOverride
  def mock_callback_call
    setup_phase
    @env['omniauth.origin'] = session.delete('omniauth.origin')
    @env['omniauth.origin'] = nil if env['omniauth.origin'] == ''
    @env['omniauth.params'] = session.delete('omniauth.params') || {}

    mocked_auth = OmniAuth.mock_auth_for(name.to_s)
    if mocked_auth.is_a?(Symbol)
      # For the purposes of this plugin, we need only simulate `CallbackError`s.
      # But if we were to upstream this, this would need to be refactored.
      mocked_exception =
        OmniAuth::Strategies::OAuth2::CallbackError.new(:immediate_failed)

      # In OmniAuth's version of this method, `#fail!` is called without an
      # exception argument, which isn't realistic.
      fail!(mocked_auth, mocked_exception)
    else
      @env['omniauth.auth'] = mocked_auth
      OmniAuth.config.before_callback_phase.call(@env) if OmniAuth.config.before_callback_phase
      call_app!
    end
  end

  OmniAuth::Strategies::OAuth2.prepend self
end
