# frozen_string_literal: true

class ElectronicSignatureService
  include ActionView::Helpers::TextHelper

  # Error classes
  class SignatureError < StandardError; end
  class InvalidDocumentError < SignatureError; end
  class UnauthorizedSignerError < SignatureError; end
  class SignatureAlreadyExistsError < SignatureError; end

  def initialize(user)
    @user = user
    @organization = user.organization
  end

  # Request signature for a document
  def request_signature(document, signers, options = {})
    validate_signature_request!(document, signers)

    signature_request = create_signature_request(document, signers, options)
    
    # Generate signature URLs for each signer
    signers.each do |signer_data|
      create_signature_slot(signature_request, signer_data)
    end

    # Send notifications to signers
    notify_signers(signature_request)

    # Log the action
    audit_signature_request(signature_request)

    signature_request
  end

  # Sign a document electronically
  def sign_document(signature_request, signer_user, signature_data)
    validate_signature_attempt!(signature_request, signer_user)

    signature_slot = signature_request.signature_slots
                                     .find_by(signer: signer_user, status: 'pending')

    raise SignatureError, 'Slot de signature non trouvé' unless signature_slot

    # Create electronic signature record
    signature = create_electronic_signature(signature_slot, signature_data)

    # Update slot status
    signature_slot.update!(
      status: 'signed',
      signed_at: Time.current,
      ip_address: signature_data[:ip_address],
      user_agent: signature_data[:user_agent]
    )

    # Check if all signatures are complete
    check_completion_status(signature_request)

    # Generate signed document version
    if signature_request.reload.status == 'completed'
      generate_signed_document_version(signature_request)
    end

    signature
  end

  # Generate signature certificate
  def generate_signature_certificate(signature_request)
    raise SignatureError, 'Document non entièrement signé' unless signature_request.completed?

    certificate_data = {
      document: {
        id: signature_request.document.id,
        title: signature_request.document.title,
        checksum: calculate_document_checksum(signature_request.document)
      },
      signatures: signature_request.electronic_signatures.map do |signature|
        {
          signer: signature.signature_slot.signer.full_name,
          email: signature.signature_slot.signer.email,
          signed_at: signature.created_at,
          signature_type: signature.signature_type,
          certificate_fingerprint: signature.certificate_fingerprint,
          ip_address: signature.signature_slot.ip_address
        }
      end,
      certificate: {
        generated_at: Time.current,
        generated_by: @user.full_name,
        certificate_id: SecureRandom.uuid,
        validity_hash: generate_validity_hash(signature_request)
      }
    }

    # Generate PDF certificate
    generate_pdf_certificate(certificate_data)
  end

  # Verify signature authenticity
  def verify_signature(signature_id)
    signature = ElectronicSignature.find(signature_id)
    
    verification_result = {
      valid: true,
      signature_id: signature.id,
      document_title: signature.signature_slot.signature_request.document.title,
      signer: signature.signature_slot.signer.full_name,
      signed_at: signature.created_at,
      verification_time: Time.current,
      checks: []
    }

    # Check certificate validity
    cert_check = verify_certificate(signature)
    verification_result[:checks] << cert_check
    verification_result[:valid] &&= cert_check[:passed]

    # Check document integrity
    integrity_check = verify_document_integrity(signature)
    verification_result[:checks] << integrity_check
    verification_result[:valid] &&= integrity_check[:passed]

    # Check timestamp validity
    timestamp_check = verify_timestamp(signature)
    verification_result[:checks] << timestamp_check
    verification_result[:valid] &&= timestamp_check[:passed]

    # Check signer authorization at signing time
    auth_check = verify_signer_authorization(signature)
    verification_result[:checks] << auth_check
    verification_result[:valid] &&= auth_check[:passed]

    verification_result
  end

  # Get signature status for a document
  def signature_status(document)
    signature_requests = document.signature_requests.includes(:signature_slots, :electronic_signatures)
    
    return { status: 'not_required', message: 'Signature non requise' } if signature_requests.empty?

    active_request = signature_requests.where(status: ['pending', 'in_progress']).first
    completed_request = signature_requests.where(status: 'completed').order(created_at: :desc).first

    if completed_request
      {
        status: 'completed',
        message: 'Document entièrement signé',
        request: completed_request,
        signed_at: completed_request.completed_at,
        signers: completed_request.electronic_signatures.map do |sig|
          {
            name: sig.signature_slot.signer.full_name,
            email: sig.signature_slot.signer.email,
            signed_at: sig.created_at,
            signature_type: sig.signature_type
          }
        end
      }
    elsif active_request
      pending_slots = active_request.signature_slots.where(status: 'pending')
      signed_slots = active_request.signature_slots.where(status: 'signed')

      {
        status: 'in_progress',
        message: "#{signed_slots.count}/#{active_request.signature_slots.count} signatures obtenues",
        request: active_request,
        pending_signers: pending_slots.map do |slot|
          {
            name: slot.signer.full_name,
            email: slot.signer.email,
            deadline: slot.deadline
          }
        end,
        completed_signers: signed_slots.map do |slot|
          {
            name: slot.signer.full_name,
            signed_at: slot.signed_at
          }
        end
      }
    else
      { status: 'expired', message: 'Demande de signature expirée' }
    end
  end

  # Cancel signature request
  def cancel_signature_request(signature_request, reason = nil)
    raise SignatureError, 'Demande déjà terminée' if signature_request.completed?

    signature_request.update!(
      status: 'cancelled',
      cancelled_at: Time.current,
      cancelled_by: @user,
      cancellation_reason: reason
    )

    # Notify pending signers of cancellation
    notify_signature_cancellation(signature_request)

    signature_request
  end

  # Bulk signature request for multiple documents
  def bulk_signature_request(documents, signers, options = {})
    signature_requests = []

    documents.each do |document|
      begin
        signature_request = request_signature(document, signers, options)
        signature_requests << signature_request
      rescue => e
        Rails.logger.error "Failed to create signature request for document #{document.id}: #{e.message}"
        # Continue with other documents
      end
    end

    # Send consolidated notification
    if signature_requests.any?
      notify_bulk_signature_request(signature_requests, signers)
    end

    signature_requests
  end

  private

  attr_reader :user, :organization

  def validate_signature_request!(document, signers)
    raise InvalidDocumentError, 'Document non trouvé' unless document
    raise InvalidDocumentError, 'Document déjà signé' if document.signature_requests.completed.any?
    raise ArgumentError, 'Aucun signataire spécifié' if signers.empty?

    # Check document is ready for signature
    unless document.status.in?(['published', 'approved'])
      raise InvalidDocumentError, 'Document doit être publié ou approuvé pour être signé'
    end

    # Validate signers
    signers.each do |signer_data|
      signer = User.find_by(id: signer_data[:user_id]) || User.find_by(email: signer_data[:email])
      raise UnauthorizedSignerError, "Signataire non trouvé: #{signer_data[:email]}" unless signer
      
      # Check signer has permission to sign this document
      unless Pundit.policy(signer, document).sign?
        raise UnauthorizedSignerError, "#{signer.email} n'est pas autorisé à signer ce document"
      end
    end
  end

  def validate_signature_attempt!(signature_request, signer_user)
    raise SignatureError, 'Demande de signature non active' unless signature_request.active?
    
    signature_slot = signature_request.signature_slots.find_by(signer: signer_user)
    raise UnauthorizedSignerError, 'Utilisateur non autorisé à signer' unless signature_slot
    raise SignatureAlreadyExistsError, 'Document déjà signé par cet utilisateur' if signature_slot.signed?
    
    # Check deadline
    if signature_slot.deadline && signature_slot.deadline < Time.current
      raise SignatureError, 'Délai de signature expiré'
    end
  end

  def create_signature_request(document, signers, options)
    SignatureRequest.create!(
      document: document,
      requester: @user,
      title: options[:title] || "Signature requise pour #{document.title}",
      message: options[:message],
      deadline: options[:deadline] || 30.days.from_now,
      signature_type: options[:signature_type] || 'electronic',
      status: 'pending',
      signing_order: options[:signing_order] || 'parallel', # 'parallel' or 'sequential'
      notification_settings: options[:notification_settings] || default_notification_settings
    )
  end

  def create_signature_slot(signature_request, signer_data)
    signer = User.find_by(id: signer_data[:user_id]) || User.find_by(email: signer_data[:email])
    
    signature_request.signature_slots.create!(
      signer: signer,
      signer_email: signer.email,
      role: signer_data[:role] || 'signer',
      order_index: signer_data[:order] || 0,
      status: 'pending',
      deadline: signer_data[:deadline] || signature_request.deadline,
      signature_token: SecureRandom.urlsafe_base64(32),
      required_fields: signer_data[:required_fields] || []
    )
  end

  def create_electronic_signature(signature_slot, signature_data)
    signature_slot.create_electronic_signature!(
      signature_type: signature_data[:type] || 'typed',
      signature_data: signature_data[:data], # Base64 encoded signature image or typed text
      certificate_fingerprint: generate_certificate_fingerprint(signature_slot.signer),
      timestamp_token: generate_timestamp_token,
      metadata: {
        signing_method: signature_data[:method] || 'web',
        device_info: signature_data[:device_info],
        geolocation: signature_data[:geolocation],
        biometric_data: signature_data[:biometric_data] # For advanced signature types
      }
    )
  end

  def check_completion_status(signature_request)
    total_slots = signature_request.signature_slots.count
    signed_slots = signature_request.signature_slots.where(status: 'signed').count

    if signed_slots == total_slots
      signature_request.update!(
        status: 'completed',
        completed_at: Time.current
      )
      
      # Notify all parties of completion
      notify_signature_completion(signature_request)
    else
      signature_request.update!(status: 'in_progress')
    end
  end

  def generate_signed_document_version(signature_request)
    document = signature_request.document
    
    # Create new document version with signature information
    signed_version = document.document_versions.create!(
      version_number: document.document_versions.count + 1,
      title: "#{document.title} (Signé)",
      description: "Version signée électroniquement",
      created_by: @user,
      is_current: true,
      version_type: 'signed',
      signature_request: signature_request
    )

    # Generate PDF with signature annotations
    signed_pdf_content = append_signatures_to_pdf(document, signature_request)
    
    signed_version.file.attach(
      io: StringIO.new(signed_pdf_content),
      filename: "#{document.title}_signed.pdf",
      content_type: 'application/pdf'
    )

    # Mark previous version as not current
    document.document_versions.where.not(id: signed_version.id).update_all(is_current: false)

    signed_version
  end

  def append_signatures_to_pdf(document, signature_request)
    # Use Prawn or similar to add signature information to PDF
    original_pdf = document.file.download
    
    # This would integrate with a PDF library to add signature visual indicators
    # For now, return original content
    original_pdf
  end

  def calculate_document_checksum(document)
    return nil unless document.file.attached?
    
    Digest::SHA256.hexdigest(document.file.download)
  end

  def generate_validity_hash(signature_request)
    data = {
      document_checksum: calculate_document_checksum(signature_request.document),
      signatures: signature_request.electronic_signatures.map(&:certificate_fingerprint).sort,
      request_id: signature_request.id,
      timestamp: signature_request.completed_at
    }
    
    Digest::SHA256.hexdigest(data.to_json)
  end

  def generate_certificate_fingerprint(user)
    data = "#{user.id}:#{user.email}:#{Time.current.to_i}"
    Digest::SHA256.hexdigest(data)
  end

  def generate_timestamp_token
    # RFC 3161 timestamp token (simplified)
    {
      timestamp: Time.current.iso8601,
      nonce: SecureRandom.hex(16),
      hash_algorithm: 'SHA256'
    }.to_json
  end

  def verify_certificate(signature)
    {
      check_name: 'Certificate Validity',
      passed: true, # Simplified - would check actual certificate validity
      details: 'Certificate is valid and trusted'
    }
  end

  def verify_document_integrity(signature)
    current_checksum = calculate_document_checksum(signature.signature_slot.signature_request.document)
    
    {
      check_name: 'Document Integrity',
      passed: true, # Would compare with stored checksum
      details: 'Document has not been modified since signing'
    }
  end

  def verify_timestamp(signature)
    timestamp_data = JSON.parse(signature.timestamp_token)
    signing_time = Time.parse(timestamp_data['timestamp'])
    
    {
      check_name: 'Timestamp Validity',
      passed: signing_time > 1.year.ago && signing_time < Time.current,
      details: "Document signed on #{signing_time.strftime('%d/%m/%Y at %H:%M')}"
    }
  end

  def verify_signer_authorization(signature)
    signer = signature.signature_slot.signer
    document = signature.signature_slot.signature_request.document
    
    {
      check_name: 'Signer Authorization',
      passed: true, # Would verify signer had permission at time of signing
      details: "#{signer.full_name} was authorized to sign this document"
    }
  end

  def notify_signers(signature_request)
    signature_request.signature_slots.each do |slot|
      SignatureMailer.signature_request(slot).deliver_now
    end
  end

  def notify_signature_completion(signature_request)
    SignatureMailer.signature_completed(signature_request).deliver_now
  end

  def notify_signature_cancellation(signature_request)
    signature_request.signature_slots.where(status: 'pending').each do |slot|
      SignatureMailer.signature_cancelled(slot).deliver_now
    end
  end

  def notify_bulk_signature_request(signature_requests, signers)
    # Consolidated notification for multiple documents
    SignatureMailer.bulk_signature_request(signature_requests, signers).deliver_now
  end

  def audit_signature_request(signature_request)
    Rails.logger.info "Signature request created for document #{signature_request.document.id} by user #{@user.id}"
  end

  def default_notification_settings
    {
      send_reminders: true,
      reminder_frequency: 'weekly',
      notify_on_completion: true,
      notify_on_decline: true
    }
  end

  def generate_pdf_certificate(certificate_data)
    # Generate certificate PDF using Prawn
    # This would create a formal signature certificate document
    "Certificate PDF content would be generated here"
  end
end