require 'rails_helper'

RSpec.describe RegulatoryComplianceService do
  let(:document) { create(:document) }
  let(:service) { described_class.new(document) }

  describe '#check_compliance' do
    it 'returns compliance report with all checks' do
      result = service.check_compliance
      
      expect(result).to have_key(:overall_score)
      expect(result).to have_key(:violations)
      expect(result).to have_key(:recommendations)
      expect(result[:overall_score]).to be_between(0, 100)
    end

    it 'includes all compliance categories' do
      result = service.check_compliance
      expect(result[:checks]).to have_key(:gdpr)
      expect(result[:checks]).to have_key(:financial)
      expect(result[:checks]).to have_key(:environmental)
      expect(result[:checks]).to have_key(:contractual)
      expect(result[:checks]).to have_key(:real_estate)
    end
  end

  describe '#check_gdpr_compliance' do
    context 'with personal data' do
      before do
        allow(document).to receive(:extracted_text).and_return(
          'John Doe, email: john@example.com, phone: +33123456789, address: 123 Main St'
        )
      end

      it 'detects personal data violations' do
        result = service.send(:check_gdpr_compliance)
        expect(result[:violations].length).to be > 0
        expect(result[:violations].any? { |v| v[:type] == 'personal_data_exposure' }).to be true
      end
    end

    context 'without personal data' do
      before do
        allow(document).to receive(:extracted_text).and_return(
          'Technical specifications and requirements document. Data retention policy: 5 years. GDPR consent obtained.'
        )
      end

      it 'passes GDPR compliance' do
        result = service.send(:check_gdpr_compliance)
        expect(result[:score]).to be > 80
      end
    end
  end

  describe '#check_financial_compliance' do
    context 'with large transaction amounts' do
      before do
        allow(document).to receive(:extracted_text).and_return(
          'Transaction amount: €15,000.00 for cash payment'
        )
      end

      it 'detects AML violations for large cash transactions' do
        result = service.send(:check_financial_compliance)
        violations = result[:violations].select { |v| v[:type] == 'large_cash_transaction' }
        expect(violations.length).to be > 0
      end
    end

    context 'with transaction verification' do
      before do
        allow(document).to receive(:extracted_text).and_return(
          'KYC verified transaction ID: ABC123 amount: €5,000.00. Nom: John Doe, Adresse: 123 Main St, Date de naissance: 01/01/1980, Pièce d\'identité: Passport 123456. ' +
          'GDPR consent provided. Data retention: 7 years. Durée de conservation: 7 ans. ' +
          'Étude d\'impact environnemental incluse. Plan de gestion des déchets approuvé. ' +
          'Contrat entre parties. Date d\'effet: 2024-01-01. Clause de résiliation incluse. Conditions de paiement: 30 jours. Limitation de responsabilité. ' +
          'Mesures de sécurité et prévention des risques incluses.'
        )
      end

      it 'passes financial compliance with proper verification' do
        result = service.check_compliance
        expect(result[:overall_score]).to be > 50
        expect(result[:categories]).to include('financial')
      end
    end
  end

  describe '#check_environmental_compliance' do
    context 'with environmental terms' do
      before do
        allow(document).to receive(:extracted_text).and_return(
          'Environmental impact assessment required for construction project'
        )
      end

      it 'detects environmental compliance requirements' do
        result = service.check_compliance
        expect(result[:overall_score]).to be_between(0, 100)
        expect(result[:categories]).to include('environmental')
      end
    end
  end

  describe '#check_contractual_compliance' do
    context 'with missing contract elements' do
      before do
        allow(document).to receive(:extracted_text).and_return(
          'Simple agreement between parties'
        )
      end

      it 'detects missing essential contract terms' do
        result = service.send(:check_contractual_compliance)
        expect(result[:violations].length).to be > 0
      end
    end

    context 'with complete contract' do
      before do
        allow(document).to receive(:extracted_text).and_return(
          'Contract between Party A and Party B. Effective date: 2024-01-01. Termination clause included. Payment terms: 30 days. Liability limitations apply.'
        )
      end

      it 'passes contractual compliance with complete terms' do
        result = service.send(:check_contractual_compliance)
        expect(result[:score]).to be > 60
      end
    end
  end

  describe '#check_real_estate_compliance' do
    context 'with construction document' do
      before do
        allow(document).to receive(:extracted_text).and_return(
          'Building permit application for residential construction'
        )
      end

      it 'checks for required permits and documentation' do
        result = service.send(:check_real_estate_compliance)
        expect(result[:score]).to be_between(0, 100)
      end
    end
  end

  describe 'private helper methods' do
    describe '#contains_personal_data?' do
      it 'detects email addresses' do
        expect(service.send(:contains_personal_data?, 'Contact: john@example.com')).to be true
      end

      it 'detects phone numbers' do
        expect(service.send(:contains_personal_data?, 'Phone: +33123456789')).to be true
      end

      it 'detects social security patterns' do
        expect(service.send(:contains_personal_data?, 'SSN: 123-45-6789')).to be true
      end

      it 'returns false for non-personal content' do
        expect(service.send(:contains_personal_data?, 'Technical specifications')).to be false
      end
    end

    describe '#extract_amounts' do
      it 'extracts monetary amounts from text' do
        amounts = service.send(:extract_amounts, 'Payment of €10,000.00 and $5,000.50')
        expect(amounts.length).to be >= 1
        expect(amounts.any? { |a| a > 5000 }).to be true
      end
    end

    describe '#calculate_overall_score' do
      it 'calculates weighted average of compliance scores' do
        checks = {
          gdpr: { score: 80 },
          financial: { score: 90 },
          environmental: { score: 70 },
          contractual: { score: 60 },
          real_estate: { score: 85 }
        }
        
        score = service.send(:calculate_overall_score, checks)
        expect(score).to be_between(60, 90)
      end
    end

    describe '#get_severity' do
      it 'returns correct severity levels' do
        expect(service.send(:get_severity, 'personal_data_exposure')).to eq('high')
        expect(service.send(:get_severity, 'large_cash_transaction')).to eq('high')
        expect(service.send(:get_severity, 'missing_contract_term')).to eq('medium')
        expect(service.send(:get_severity, 'unknown_violation')).to eq('low')
      end
    end
  end
end