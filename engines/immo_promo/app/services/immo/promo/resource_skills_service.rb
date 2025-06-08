module Immo
  module Promo
    class ResourceSkillsService
      attr_reader :project

      def initialize(project)
        @project = project
      end

      def analyze_skills_matrix
        {
          available_skills: compile_available_skills,
          required_skills: compile_required_skills,
          skill_gaps: identify_skill_gaps,
          skill_coverage: calculate_skill_coverage,
          recommendations: generate_skill_recommendations
        }
      end

      def compile_available_skills
        skills_map = Hash.new { |h, k| h[k] = [] }
        
        project.stakeholders.active.includes(:certifications).each do |stakeholder|
          stakeholder.certifications.each do |certification|
            skills_map[certification.certification_type] << {
              stakeholder: stakeholder,
              certification: certification,
              expiry_date: certification.expiry_date,
              is_expired: certification.expiry_date && certification.expiry_date < Date.current
            }
          end
        end
        
        skills_map.transform_values do |holders|
          {
            total_holders: holders.count,
            active_holders: holders.reject { |h| h[:is_expired] }.count,
            stakeholders: holders.map { |h| h[:stakeholder] }.uniq,
            expiring_soon: holders.select { |h| 
              h[:expiry_date] && h[:expiry_date].between?(Date.current, 30.days.from_now)
            }.count
          }
        end
      end

      def compile_required_skills
        required_skills = Hash.new(0)
        
        # From tasks
        project.tasks.where.not(status: 'completed').each do |task|
          next if task.required_skills.blank?
          
          task.required_skills.each do |skill|
            required_skills[skill] += 1
          end
        end
        
        # From phase requirements
        project.phases.each do |phase|
          phase_required_skills(phase.phase_type).each do |skill|
            required_skills[skill] += 1
          end
        end
        
        required_skills
      end

      def identify_skill_gaps
        available = compile_available_skills
        required = compile_required_skills
        
        gaps = []
        
        required.each do |skill, demand|
          supply = available[skill]
          
          if supply.nil? || supply[:active_holders] == 0
            gaps << {
              skill: skill,
              severity: 'critical',
              demand: demand,
              supply: 0,
              gap: demand,
              message: "No qualified resources for #{skill}"
            }
          elsif supply[:active_holders] < demand
            gaps << {
              skill: skill,
              severity: 'high',
              demand: demand,
              supply: supply[:active_holders],
              gap: demand - supply[:active_holders],
              message: "Insufficient #{skill} resources"
            }
          elsif supply[:expiring_soon] > 0
            gaps << {
              skill: skill,
              severity: 'medium',
              demand: demand,
              supply: supply[:active_holders],
              gap: 0,
              message: "#{supply[:expiring_soon]} #{skill} certifications expiring soon"
            }
          end
        end
        
        gaps.sort_by { |g| severity_priority(g[:severity]) }
      end

      def calculate_skill_coverage
        available = compile_available_skills
        required = compile_required_skills
        
        return 100.0 if required.empty?
        
        covered_skills = required.keys.count { |skill| 
          available[skill] && available[skill][:active_holders] > 0 
        }
        
        (covered_skills.to_f / required.keys.count * 100).round(2)
      end

      def find_skill_dependencies
        dependencies = []
        
        project.phases.includes(:tasks).each do |phase|
          phase_skills = phase_required_skills(phase.phase_type)
          
          phase.tasks.each do |task|
            next if task.required_skills.blank?
            
            task.required_skills.each do |skill|
              if task.prerequisite_tasks.any?
                prereq_skills = task.prerequisite_tasks.flat_map(&:required_skills).uniq
                
                dependencies << {
                  phase: phase,
                  task: task,
                  skill: skill,
                  depends_on: prereq_skills,
                  type: 'sequential'
                }
              end
            end
          end
        end
        
        dependencies
      end

      def analyze_skill_redundancy
        available_skills = compile_available_skills
        
        redundancy_analysis = {}
        
        available_skills.each do |skill, data|
          redundancy_analysis[skill] = {
            redundancy_level: calculate_redundancy_level(data[:active_holders]),
            risk_assessment: assess_redundancy_risk(skill, data),
            recommendations: redundancy_recommendations(skill, data)
          }
        end
        
        redundancy_analysis
      end

      def generate_skill_recommendations
        recommendations = []
        gaps = identify_skill_gaps
        redundancy = analyze_skill_redundancy
        
        # Critical gaps
        gaps.select { |g| g[:severity] == 'critical' }.each do |gap|
          recommendations << {
            type: 'skill_gap',
            priority: 'urgent',
            skill: gap[:skill],
            action: "Immediately acquire #{gap[:skill]} capability",
            options: [
              'Hire qualified professional',
              'Urgent training for existing staff',
              'Subcontract to qualified vendor'
            ]
          }
        end
        
        # Low redundancy
        redundancy.select { |_, data| data[:redundancy_level] == 'low' }.each do |skill, data|
          recommendations << {
            type: 'redundancy_risk',
            priority: 'high',
            skill: skill,
            action: "Increase redundancy for #{skill}",
            options: data[:recommendations]
          }
        end
        
        # Expiring certifications
        expiring_certifications.each do |cert_data|
          recommendations << {
            type: 'certification_renewal',
            priority: 'medium',
            stakeholder: cert_data[:stakeholder],
            certification: cert_data[:certification],
            action: "Renew #{cert_data[:certification].certification_type} certification",
            deadline: cert_data[:certification].expiry_date
          }
        end
        
        recommendations.sort_by { |r| priority_value(r[:priority]) }
      end

      private

      def phase_required_skills(phase_type)
        case phase_type.to_s
        when 'studies'
          ['architect_license', 'engineering_certification']
        when 'permits'
          ['architect_license', 'regulatory_certification']
        when 'construction'
          ['construction_license', 'safety_certification', 'quality_certification']
        when 'reception'
          ['quality_certification', 'compliance_certification']
        else
          []
        end
      end

      def severity_priority(severity)
        case severity
        when 'critical' then 1
        when 'high' then 2
        when 'medium' then 3
        else 4
        end
      end

      def calculate_redundancy_level(holder_count)
        case holder_count
        when 0 then 'none'
        when 1 then 'low'
        when 2..3 then 'moderate'
        else 'high'
        end
      end

      def assess_redundancy_risk(skill, data)
        if data[:active_holders] == 0
          'critical'
        elsif data[:active_holders] == 1
          'high'
        elsif data[:expiring_soon] > 0
          'medium'
        else
          'low'
        end
      end

      def redundancy_recommendations(skill, data)
        recommendations = []
        
        case data[:active_holders]
        when 0
          recommendations << "Urgently acquire #{skill} capability"
        when 1
          recommendations << "Train backup resource for #{skill}"
          recommendations << "Document #{skill} procedures"
        when 2..3
          recommendations << "Monitor #{skill} capacity"
        end
        
        if data[:expiring_soon] > 0
          recommendations << "Schedule certification renewals"
        end
        
        recommendations
      end

      def expiring_certifications
        certifications = []
        
        project.stakeholders.active.includes(:certifications).each do |stakeholder|
          stakeholder.certifications.each do |certification|
            if certification.expiry_date && certification.expiry_date.between?(Date.current, 30.days.from_now)
              certifications << {
                stakeholder: stakeholder,
                certification: certification
              }
            end
          end
        end
        
        certifications
      end

      def priority_value(priority)
        case priority
        when 'urgent' then 1
        when 'high' then 2
        when 'medium' then 3
        else 4
        end
      end
    end
  end
end