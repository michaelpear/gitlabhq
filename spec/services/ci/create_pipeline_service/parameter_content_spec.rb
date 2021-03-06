# frozen_string_literal: true

require 'spec_helper'

describe Ci::CreatePipelineService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:admin) }
  let(:service) { described_class.new(project, user, { ref: 'refs/heads/master' }) }
  let(:content) do
    <<~EOY
      ---
      stages:
        - dast

      variables:
        DAST_VERSION: 1
        SECURE_ANALYZERS_PREFIX: "registry.gitlab.com/gitlab-org/security-products/analyzers"

      dast:
        stage: dast
        image:
          name: "$SECURE_ANALYZERS_PREFIX/dast:$DAST_VERSION"
        variables:
          GIT_STRATEGY: none
        script:
          - /analyze
    EOY
  end

  describe '#execute' do
    subject { service.execute(:web, content: content) }

    context 'parameter config content' do
      it 'creates a pipeline' do
        expect(subject).to be_persisted
      end

      it 'creates builds with the correct names' do
        expect(subject.builds.pluck(:name)).to match_array %w[dast]
      end

      it 'creates stages with the correct names' do
        expect(subject.stages.pluck(:name)).to match_array %w[dast]
      end

      it 'sets the correct config source' do
        expect(subject.config_source).to eq 'parameter_source'
      end
    end
  end
end
