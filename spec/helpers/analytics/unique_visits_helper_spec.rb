# frozen_string_literal: true

require "spec_helper"

describe Analytics::UniqueVisitsHelper do
  include Devise::Test::ControllerHelpers

  describe '#track_visit' do
    let(:target_id) { 'p_analytics_valuestream' }
    let(:current_user) { create(:user) }

    before do
      stub_feature_flags(track_unique_visits: true)
    end

    it 'does not track visits if feature flag disabled' do
      stub_feature_flags(track_unique_visits: false)
      sign_in(current_user)

      expect_any_instance_of(Gitlab::Analytics::UniqueVisits).not_to receive(:track_visit)

      helper.track_visit(target_id)
    end

    it 'does not track visits if usage ping is disabled' do
      sign_in(current_user)
      expect(Gitlab::CurrentSettings).to receive(:usage_ping_enabled?).and_return(false)

      expect_any_instance_of(Gitlab::Analytics::UniqueVisits).not_to receive(:track_visit)

      helper.track_visit(target_id)
    end

    it 'does not track visit if user is not logged in' do
      expect_any_instance_of(Gitlab::Analytics::UniqueVisits).not_to receive(:track_visit)

      helper.track_visit(target_id)
    end

    it 'tracks visit if user is logged in' do
      sign_in(current_user)

      expect_any_instance_of(Gitlab::Analytics::UniqueVisits).to receive(:track_visit)

      helper.track_visit(target_id)
    end

    it 'tracks visit if user is not logged in, but has the cookie already' do
      helper.request.cookies[:visitor_id] = { value: SecureRandom.uuid, expires: 24.months }

      expect_any_instance_of(Gitlab::Analytics::UniqueVisits).to receive(:track_visit)

      helper.track_visit(target_id)
    end
  end
end
