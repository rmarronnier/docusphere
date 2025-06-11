require 'rails_helper'

module Immo
  module Promo
    RSpec.describe ProgressCacheService do
      let(:redis) { Rails.cache.redis }
      let(:organization) { create(:organization) }
      let(:project) { create(:immo_promo_project, organization: organization) }
      let(:phase) { create(:immo_promo_phase, project: project) }

      before do
        Rails.cache.clear
      end

      describe '.project_progress' do
        context 'when cache is empty' do
          it 'calculates and caches project progress' do
            allow(ProjectProgressService).to receive(:new).with(project).and_return(
              double(calculate_progress: { overall: 75, by_phase: {} })
            )

            result = described_class.project_progress(project)

            expect(result).to eq({ overall: 75, by_phase: {} })
            expect(Rails.cache.exist?("project_progress:#{project.id}")).to be true
          end

          it 'returns progress data structure' do
            service_double = double('progress_service')
            allow(ProjectProgressService).to receive(:new).and_return(service_double)
            allow(service_double).to receive(:calculate_progress).and_return(
              overall: 50,
              by_phase: { 'phase1' => 75, 'phase2' => 25 },
              milestones_completed: 5,
              milestones_total: 10
            )

            result = described_class.project_progress(project)

            expect(result[:overall]).to eq(50)
            expect(result[:by_phase]).to eq({ 'phase1' => 75, 'phase2' => 25 })
            expect(result[:milestones_completed]).to eq(5)
            expect(result[:milestones_total]).to eq(10)
          end
        end

        context 'when cache exists' do
          let(:cached_data) { { overall: 80, by_phase: { 'phase1' => 100 } } }

          before do
            Rails.cache.write("project_progress:#{project.id}", cached_data, expires_in: 1.hour)
          end

          it 'returns cached data without recalculating' do
            expect(ProjectProgressService).not_to receive(:new)

            result = described_class.project_progress(project)

            expect(result).to eq(cached_data)
          end
        end

        it 'handles cache expiration correctly' do
          service_double = double('progress_service')
          allow(ProjectProgressService).to receive(:new).and_return(service_double)
          
          # First call - calculates
          allow(service_double).to receive(:calculate_progress).and_return({ overall: 60 })
          first_result = described_class.project_progress(project)
          
          # Second call - uses cache
          second_result = described_class.project_progress(project)
          
          expect(first_result).to eq(second_result)
          expect(service_double).to have_received(:calculate_progress).once
        end
      end

      describe '.phase_progress' do
        context 'when cache is empty' do
          it 'calculates and caches phase progress' do
            allow_any_instance_of(Phase).to receive(:progress_percentage).and_return(45)

            result = described_class.phase_progress(phase)

            expect(result).to eq(45)
            expect(Rails.cache.exist?("phase_progress:#{phase.id}")).to be true
          end
        end

        context 'when cache exists' do
          before do
            Rails.cache.write("phase_progress:#{phase.id}", 65, expires_in: 30.minutes)
          end

          it 'returns cached progress' do
            expect_any_instance_of(Phase).not_to receive(:progress_percentage)

            result = described_class.phase_progress(phase)

            expect(result).to eq(65)
          end
        end
      end

      describe '.clear_project_cache' do
        let!(:phase1) { create(:immo_promo_phase, project: project) }
        let!(:phase2) { create(:immo_promo_phase, project: project) }

        before do
          # Set up cached data
          Rails.cache.write("project_progress:#{project.id}", { overall: 50 })
          Rails.cache.write("phase_progress:#{phase1.id}", 60)
          Rails.cache.write("phase_progress:#{phase2.id}", 40)
        end

        it 'clears project cache' do
          described_class.clear_project_cache(project)

          expect(Rails.cache.exist?("project_progress:#{project.id}")).to be false
        end

        it 'clears all associated phase caches' do
          described_class.clear_project_cache(project)

          expect(Rails.cache.exist?("phase_progress:#{phase1.id}")).to be false
          expect(Rails.cache.exist?("phase_progress:#{phase2.id}")).to be false
        end

        it 'does not affect other project caches' do
          other_project = create(:immo_promo_project, organization: organization)
          Rails.cache.write("project_progress:#{other_project.id}", { overall: 70 })

          described_class.clear_project_cache(project)

          expect(Rails.cache.exist?("project_progress:#{other_project.id}")).to be true
        end
      end

      describe '.clear_phase_cache' do
        before do
          Rails.cache.write("phase_progress:#{phase.id}", 55)
          Rails.cache.write("project_progress:#{project.id}", { overall: 60 })
        end

        it 'clears phase cache' do
          described_class.clear_phase_cache(phase)

          expect(Rails.cache.exist?("phase_progress:#{phase.id}")).to be false
        end

        it 'also clears parent project cache' do
          described_class.clear_phase_cache(phase)

          expect(Rails.cache.exist?("project_progress:#{project.id}")).to be false
        end
      end

      describe '.clear_all' do
        before do
          Rails.cache.write("project_progress:1", { overall: 50 })
          Rails.cache.write("phase_progress:1", 60)
          Rails.cache.write("other_key", "value")
        end

        it 'clears all progress-related caches' do
          described_class.clear_all

          expect(Rails.cache.exist?("project_progress:1")).to be false
          expect(Rails.cache.exist?("phase_progress:1")).to be false
        end

        it 'does not clear non-progress caches' do
          described_class.clear_all

          expect(Rails.cache.exist?("other_key")).to be true
        end
      end

      describe 'cache expiration' do
        it 'uses 1 hour expiration for project progress' do
          allow(ProjectProgressService).to receive(:new).and_return(
            double(calculate_progress: { overall: 75 })
          )

          described_class.project_progress(project)

          ttl = redis.ttl("cache:#{Rails.env}:project_progress:#{project.id}")
          expect(ttl).to be > 0
          expect(ttl).to be <= 3600
        end

        it 'uses 30 minutes expiration for phase progress' do
          allow_any_instance_of(Phase).to receive(:progress_percentage).and_return(45)

          described_class.phase_progress(phase)

          ttl = redis.ttl("cache:#{Rails.env}:phase_progress:#{phase.id}")
          expect(ttl).to be > 0
          expect(ttl).to be <= 1800
        end
      end
    end
  end
end