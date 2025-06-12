# frozen_string_literal: true

module Ged
  class DocumentSharesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_document
    
    def create
      authorize @document, :share?
      
      user = User.find_by(email: share_params[:email])
      
      if user.nil?
        # Option 1: Create an invitation
        # Option 2: Return error
        render json: { error: "L'utilisateur avec cet email n'existe pas dans le système" }, status: :unprocessable_entity
        return
      end
      
      if user == current_user
        render json: { error: "Vous ne pouvez pas partager un document avec vous-même" }, status: :unprocessable_entity
        return
      end
      
      # Check if already shared with this user
      existing_share = @document.document_shares.find_by(shared_with: user)
      
      if existing_share
        # Update existing share
        existing_share.update!(access_level: share_params[:permission])
        share = existing_share
      else
        # Create new share
        share = @document.document_shares.build(
          shared_with: user,
          shared_by: current_user,
          access_level: share_params[:permission],
          email: user.email
        )
        
        if !share.save
          render json: { error: share.errors.full_messages.join(', ') }, status: :unprocessable_entity
          return
        end
      end
      
      # Send notification
      if share_params[:message].present?
        NotificationService.new.notify_document_shared(
          document: @document,
          recipient: user,
          sender: current_user,
          message: share_params[:message]
        )
      else
        NotificationService.new.notify_document_shared(
          document: @document,
          recipient: user,
          sender: current_user
        )
      end
      
      respond_to do |format|
        format.json do
          render json: { 
            success: true, 
            message: "Document partagé avec succès",
            share: {
              id: share.id,
              user_name: user.display_name,
              permission: share.access_level
            }
          }
        end
        format.html do
          redirect_to ged_document_path(@document), notice: "Document partagé avec succès"
        end
      end
    end
    
    def destroy
      share = @document.document_shares.find(params[:id])
      authorize @document, :share?
      
      share.destroy
      
      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_to ged_document_path(@document), notice: "Partage supprimé" }
      end
    end
    
    private
    
    def set_document
      @document = policy_scope(Document).find(params[:document_id])
    end
    
    def share_params
      params.permit(:email, :permission, :message)
    end
  end
end