require 'rails_helper'

RSpec.describe Immo::Promo::ResourceSkillsService do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { described_class.new(project) }
  
  describe '#analyze_skills_matrix' do
    let!(:architect) do
      stakeholder = create(:immo_promo_stakeholder, project: project, stakeholder_type: 'architect')
      create(:immo_promo_certification,
        stakeholder: stakeholder,
        certification_type: 'qualification',
        is_valid: true,
        expiry_date: 1.year.from_now
      )
      stakeholder
    end
    
    let!(:engineer) do
      stakeholder = create(:immo_promo_stakeholder, project: project, stakeholder_type: 'engineer')
      create(:immo_promo_certification,
        stakeholder: stakeholder,
        certification_type: 'environmental',
        is_valid: true,
        expiry_date: 2.months.from_now
      )
      stakeholder
    end
    
    let!(:phase) { create(:immo_promo_phase, project: project, phase_type: 'construction') }
    let!(:task) do
      create(:immo_promo_task,
        phase: phase,
        required_skills: ['qualification', 'rge']
      )
    end
    
    it 'compiles available skills' do
      result = service.analyze_skills_matrix
      
      expect(result[:available_skills]).to be_a(Hash)
      expect(result[:available_skills]['qualification']).to include(
        :total_holders,
        :active_holders,
        :stakeholders,
        :expiring_soon
      )
    end
    
    it 'compiles required skills' do
      result = service.analyze_skills_matrix
      
      expect(result[:required_skills]).to be_a(Hash)
      expect(result[:required_skills]).to have_key('qualification')
    end
    
    it 'identifies skill gaps' do
      result = service.analyze_skills_matrix
      
      expect(result[:skill_gaps]).to be_an(Array)
      safety_gap = result[:skill_gaps].find { |g| g[:skill] == 'rge' }
      expect(safety_gap).to be_present
      expect(safety_gap[:severity]).to eq('critical')
    end
    
    it 'calculates skill coverage' do
      result = service.analyze_skills_matrix
      
      expect(result[:skill_coverage]).to be_a(Numeric)
      expect(result[:skill_coverage]).to be_between(0, 100)
    end
    
    it 'provides recommendations' do
      result = service.analyze_skills_matrix
      
      expect(result[:recommendations]).to be_an(Array)
    end
  end
  
  describe '#identify_skill_gaps' do
    context 'with missing critical skills' do
      let!(:phase) { create(:immo_promo_phase, project: project, phase_type: 'construction') }
      
      before do
        # Create task requiring unavailable skill
        create(:immo_promo_task,
          phase: phase,
          required_skills: ['control_certification']
        )
      end
      
      it 'identifies critical gaps' do
        gaps = service.identify_skill_gaps
        
        critical_gap = gaps.find { |g| g[:severity] == 'critical' }
        expect(critical_gap).to be_present
        expect(critical_gap[:skill]).to eq('control_certification')
      end
    end
    
    context 'with expiring certifications' do
      let!(:stakeholder) do
        stakeholder = create(:immo_promo_stakeholder, project: project)
        create(:immo_promo_certification,
          stakeholder: stakeholder,
          certification_type: 'insurance',
          is_valid: true,
          expiry_date: 2.weeks.from_now
        )
        stakeholder
      end
      
      let!(:phase) { create(:immo_promo_phase, project: project) }
      let!(:task) do
        create(:immo_promo_task,
          phase: phase,
          required_skills: ['insurance']
        )
      end
      
      it 'identifies expiring certifications as medium severity' do
        gaps = service.identify_skill_gaps
        
        expiring_gap = gaps.find { |g| g[:skill] == 'insurance' }
        expect(expiring_gap).to be_present
        expect(expiring_gap[:severity]).to eq('medium')
      end
    end
  end
  
  describe '#find_skill_dependencies' do
    let!(:phase1) { create(:immo_promo_phase, project: project, phase_type: 'studies') }
    let!(:phase2) { create(:immo_promo_phase, project: project, phase_type: 'construction') }
    
    let!(:task1) do
      create(:immo_promo_task,
        phase: phase1,
        required_skills: ['qualification']
      )
    end
    
    let!(:task2) do
      task = create(:immo_promo_task,
        phase: phase2,
        required_skills: ['insurance']
      )
      create(:immo_promo_task_dependency, prerequisite_task: task1, dependent_task: task)
      task
    end
    
    it 'identifies skill dependencies between tasks' do
      dependencies = service.find_skill_dependencies
      
      expect(dependencies).to be_an(Array)
      dependency = dependencies.first
      expect(dependency).to include(:phase, :task, :skill, :depends_on)
    end
  end
  
  describe '#analyze_skill_redundancy' do
    context 'with single point of failure' do
      let!(:architect) do
        stakeholder = create(:immo_promo_stakeholder, project: project, stakeholder_type: 'architect')
        create(:immo_promo_certification,
          stakeholder: stakeholder,
          certification_type: 'qualification',
          is_valid: true
        )
        stakeholder
      end
      
      it 'identifies low redundancy risks' do
        analysis = service.analyze_skill_redundancy
        
        architect_redundancy = analysis['qualification']
        expect(architect_redundancy[:redundancy_level]).to eq('low')
        expect(architect_redundancy[:risk_assessment]).to eq('high')
      end
    end
    
    context 'with adequate redundancy' do
      let!(:stakeholders) do
        3.times.map do
          stakeholder = create(:immo_promo_stakeholder, project: project)
          create(:immo_promo_certification,
            stakeholder: stakeholder,
            certification_type: 'rge',
            is_valid: true
          )
          stakeholder
        end
      end
      
      it 'identifies moderate redundancy' do
        analysis = service.analyze_skill_redundancy
        
        safety_redundancy = analysis['rge']
        expect(safety_redundancy[:redundancy_level]).to eq('moderate')
      end
    end
  end
  
  describe '#generate_skill_recommendations' do
    context 'with critical skill gaps' do
      let!(:phase) { create(:immo_promo_phase, project: project, phase_type: 'permits') }
      
      before do
        create(:immo_promo_task,
          phase: phase,
          required_skills: ['regulatory_certification']
        )
      end
      
      it 'prioritizes urgent skill acquisition' do
        recommendations = service.generate_skill_recommendations
        
        urgent_rec = recommendations.find { |r| r[:priority] == 'urgent' }
        expect(urgent_rec).to be_present
        expect(urgent_rec[:type]).to eq('skill_gap')
      end
    end
    
    context 'with expiring certifications' do
      let!(:stakeholder) do
        stakeholder = create(:immo_promo_stakeholder, project: project)
        create(:immo_promo_certification,
          stakeholder: stakeholder,
          certification_type: 'insurance',
          is_valid: true,
          expiry_date: 3.weeks.from_now
        )
        stakeholder
      end
      
      it 'recommends certification renewal' do
        recommendations = service.generate_skill_recommendations
        
        renewal_rec = recommendations.find { |r| r[:type] == 'certification_renewal' }
        expect(renewal_rec).to be_present
        expect(renewal_rec[:priority]).to eq('medium')
      end
    end
  end
end