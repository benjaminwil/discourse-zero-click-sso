# frozen_string_literal: true

RSpec.describe ZeroClickSso do
  describe ".attemptable?" do
    subject { ZeroClickSso.attemptable? }

    context "when local logins are enabled" do
      before { SiteSetting.enable_local_logins = true }

      it { is_expected.to eq(false) }
    end

    context "when there are no enabled authenticators" do
      before do
        SiteSetting.enable_local_logins = false
        allow(Discourse).to receive(:enabled_authenticators).and_return([])
      end

      it { is_expected.to eq(false) }
    end

    context "when there are multiple enabled authenticators" do
      before do
        SiteSetting.enable_local_logins = false
        authenticator1 = instance_double("Auth::ManagedAuthenticator", name: "google_oauth2")
        authenticator2 = instance_double("Auth::ManagedAuthenticator", name: "github")
        allow(Discourse).to receive(:enabled_authenticators).and_return(
          [authenticator1, authenticator2],
        )
      end

      it { is_expected.to eq(false) }
    end

    context "when there is one enabled authenticator but it's not supported" do
      before do
        SiteSetting.enable_local_logins = false
        authenticator = instance_double("Auth::ManagedAuthenticator", name: "unsupported_provider")
        allow(Discourse).to receive(:enabled_authenticators).and_return([authenticator])
      end

      it { is_expected.to eq(false) }
    end

    context "when all conditions are met" do
      before do
        SiteSetting.enable_local_logins = false
        authenticator = instance_double("Auth::ManagedAuthenticator", name: "google_oauth2")
        allow(Discourse).to receive(:enabled_authenticators).and_return([authenticator])
      end

      it { is_expected.to eq(true) }
    end
  end
end
