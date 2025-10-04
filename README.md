# discourse-zero-click-sso

**Plugin Summary**

For more information, please see: **url to meta topic**

Currently, the plugin only supports zero-click logins for when Google is the
only configured SSO provider.

## Manually testing the plugin functionality in development

If you want to manually test the functionality of this plugin, you must create a
real Google OAuth2 Client in [Google Cloud](https://cloud.google.com). If you
already have Google Cloud Console access, you can go to
[console.cloud.google.com/auth/clients](https://console.cloud.google.com/auth/clients)
to get started.

### Setting up

In Google Cloud:

1. Create a new Google OAuth2 Client with an application type of **Web application**.
2. Add your **authorised JavaScript origins** and **authorised redirect URIs**.
   For a typical Discourse development environment setup:
   - Authorised JavaScript origin: `http://127.0.0.1:4200`
   - Authorised redirect URI: `http://127.0.0.1:4200/auth/google_oauth2/callback`
2. On creation, copy down the **client ID** and **client secret** somewhere
   secure like a password manager--or directly into your local Discourse configuration
   settings.

In the Discourse web application:

1. Log in as an admin user.
2. Navigate to **[Admin -> Community -> Login &
   authentication](http://127.0.0.1:4200/admin/config/login-and-authentication)**.
3. Uncheck the **Enable local logins** checkbox.
4. Check the **Enable Google OAuth2 logins** checkbox.
5. Enter **Google OAuth2 client ID** and **Google OAuth2 client secret** values
   you retrieved from Google Cloud.
6. Ensure all _all_ of the other login providers have been disabled (i.e.
   **Enable Twitter logins** should be **disabled**.)

### Test scenarios

After completing the setup described above, you can test the functionality of
this plugin using the following scenarios as a guide.

**Scenario 1: No Google SSO session.**

1. Navigate to [accounts.google.com](https://accounts.google.com) and confirm
   you are logged out of all Google accounts.
2. In your browser settings, ensure you have none or have deleted all cookies
   for the `127.0.0.1` domain.
3. Navigate to any page of the Discourse webapp (i.e. `/` or `/latest`) and
   ensure you remain logged out and that the pages do not raise exceptions.
4. Navigate to `/login` and see the normal Google login page.
5. Navigate to `/signup` and see the normal Google signup page.

Because this plugin does not make any changes to the login or signup flow, we
don't need to test beyond this. Discourse's core test suite gives us confidence
that these flows continue to work.

**Scenario 2: Logged in with a Google account that is not associated with a
DWW without an existing iscourse user account.**

Note that if you need to check whether your Google account is associated with a
Discourse user you can do this from a Rails console:

```ruby
me = User.find_by(email: MY_EMAIL)
my_associated_google_accounts =
  me.user_associated_accounts.where(provider_name: "google_oauth2")
my_associated_google_accounts.destroy_all
```

2. Navigate to [accounts.google.com](https://accounts.google.com) and confirm
   you are logged into a Google account.
3. In your browser settings, ensure you have none or have deleted all cookies
   for the `127.0.0.1` domain.
4. Navigate to any page of the Discourse webapp (i.e. `/` or `/latest`) and
   ensure you remain logged out and that the pages do not raise exceptions.
5. Navigate to `/login` and expect to be redirected to `/signup` with your
   Google email pre-filled.

**Scenario 3: Logged in with a Google account that is associated with an
existing Discourse user account.**

Ensure your Google account is associated with a Discourse user account before
starting (see **Scenario 2** for guidance).

1. Navigate to [accounts.google.com](https://accounts.google.com) and confirm
   you are logged into a Google account.
2. In your browser settings, ensure you have none or have deleted all cookies
   for the `127.0.0.1` domain.
3. Navigate to any page of the Discourse webapp (i.e. `/` or `/latest`) and
   ensure you have been logged into your existing Discourse user account.

**Scenario 4: Allow browsing Discourse logged out.**

One way to test this scenario is to go through **Scenario 3** to get set up.

1. In your browser settings, ensure you **do** have cookies for the `127.0.0.1`
   domain (that are related to your Discourse instance, not some other
   application in development).
2. Navigate to any page of the Discourse webapp (i.e. `/` or `/latest`).
3. If you are logged in, log out. If you are logged out, remain logged out.
4. Browse to other pages and ensure you remain logged out.
