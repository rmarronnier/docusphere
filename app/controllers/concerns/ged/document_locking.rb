module Ged
  module DocumentLocking
    extend ActiveSupport::Concern

    def lock_document
      # authorize already called in set_document
      
      if @document.locked? && @document.locked_by != current_user
        render json: {
          success: false,
          error: "Document déjà verrouillé par #{@document.locked_by&.full_name}"
        }, status: :conflict
      else
        # If locked by same user, update the lock reason
        if @document.locked? && @document.locked_by == current_user
          @document.update!(lock_reason: lock_params[:reason])
        else
          @document.lock_document!(current_user, reason: lock_params[:reason])
        end
        
        render json: {
          success: true,
          message: 'Document verrouillé avec succès',
          locked_until: @document.unlock_scheduled_at
        }
      end
    end

    def unlock_document
      # authorize already called in set_document
      
      unless @document.locked?
        render json: {
          success: false,
          error: 'Document non verrouillé'
        }, status: :unprocessable_entity
        return
      end

      # Check if user can unlock (either normally or via force unlock)
      if @document.can_unlock?(current_user) || policy(@document).force_unlock?
        # Directly use AASM unlock! to bypass can_unlock? check in unlock_document!
        @document.unlock!
        render json: {
          success: true,
          message: 'Document déverrouillé avec succès'
        }
      else
        render json: {
          success: false,
          error: 'Vous ne pouvez pas déverrouiller ce document'
        }, status: :forbidden
      end
    end

    private

    def lock_params
      params.permit(:reason, :duration)
    end
  end
end