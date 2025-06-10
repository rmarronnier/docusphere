class NotificationService
  class << self
    def notify_validation_requested(validation_request)
      validation_request.validators.each do |validator|
        Notification.notify_user(
          validator,
          :document_validation_requested,
          "Validation demandée",
          "#{validation_request.requester.full_name} demande votre validation pour '#{validatable_title(validation_request.validatable)}'",
          notifiable: validation_request,
          data: {
            validatable_type: validation_request.validatable_type,
            validatable_id: validation_request.validatable_id,
            requester_id: validation_request.requester.id,
            min_validations: validation_request.min_validations
          }
        )
      end
    end
    
    def notify_validation_approved(validation_request)
      Notification.notify_user(
        validation_request.requester,
        :document_validation_approved,
        "Validation approuvée",
        "Votre demande de validation pour '#{validatable_title(validation_request.validatable)}' a été approuvée",
        notifiable: validation_request,
        data: {
          validatable_type: validation_request.validatable_type,
          validatable_id: validation_request.validatable_id,
          approved_count: validation_request.document_validations.approved.count,
          total_validators: validation_request.document_validations.count
        }
      )
    end
    
    def notify_validation_rejected(validation_request)
      rejecting_validation = validation_request.document_validations.rejected.last
      
      Notification.notify_user(
        validation_request.requester,
        :document_validation_rejected,
        "Validation refusée",
        "Votre demande de validation pour '#{validatable_title(validation_request.validatable)}' a été refusée par #{rejecting_validation.validator.full_name}",
        notifiable: validation_request,
        data: {
          validatable_type: validation_request.validatable_type,
          validatable_id: validation_request.validatable_id,
          rejected_by: rejecting_validation.validator.full_name,
          rejection_comment: rejecting_validation.comment
        }
      )
    end
    
    def notify_document_shared(document, shared_with_user, shared_by_user)
      Notification.notify_user(
        shared_with_user,
        :document_shared,
        "Document partagé",
        "#{shared_by_user.full_name} a partagé le document '#{document.title}' avec vous",
        notifiable: document,
        data: {
          document_id: document.id,
          shared_by: shared_by_user.full_name
        }
      )
    end
    
    def notify_authorization_granted(authorizable, user, permission_type, granted_by)
      message = "#{granted_by.full_name} vous a accordé la permission '#{permission_type}' sur #{authorizable.class.name.downcase} '#{authorizable_title(authorizable)}'"
      
      Notification.notify_user(
        user,
        :authorization_granted,
        "Permission accordée",
        message,
        notifiable: authorizable,
        data: {
          permission_type: permission_type,
          granted_by: granted_by.full_name,
          authorizable_type: authorizable.class.name,
          authorizable_id: authorizable.id
        }
      )
    end
    
    def notify_authorization_revoked(authorizable, user, permission_type, revoked_by)
      message = "#{revoked_by.full_name} a révoqué votre permission '#{permission_type}' sur #{authorizable.class.name.downcase} '#{authorizable_title(authorizable)}'"
      
      Notification.notify_user(
        user,
        :authorization_revoked,
        "Permission révoquée",
        message,
        notifiable: authorizable,
        data: {
          permission_type: permission_type,
          revoked_by: revoked_by.full_name,
          authorizable_type: authorizable.class.name,
          authorizable_id: authorizable.id
        }
      )
    end
    
    def notify_document_processing_completed(document)
      Notification.notify_user(
        document.uploaded_by,
        :document_processing_completed,
        "Traitement terminé",
        "Le traitement du document '#{document.title}' est terminé",
        notifiable: document,
        data: {
          document_id: document.id,
          processing_time: document.processing_metadata&.dig('processing_time')
        }
      )
    end
    
    def notify_document_processing_failed(document, error)
      Notification.notify_user(
        document.uploaded_by,
        :document_processing_failed,
        "Échec du traitement",
        "Le traitement du document '#{document.title}' a échoué: #{error}",
        notifiable: document,
        data: {
          document_id: document.id,
          error_message: error
        }
      )
    end
    
    def notify_system_announcement(users, title, message, data: {})
      users.each do |user|
        Notification.notify_user(
          user,
          :system_announcement,
          title,
          message,
          data: data
        )
      end
    end

    # ImmoPromo Project Notifications
    def notify_project_created(project, stakeholders = [])
      recipients = [project.created_by] + stakeholders
      recipients.uniq.each do |user|
        Notification.notify_user(
          user,
          :project_created,
          "Nouveau projet créé",
          "Le projet '#{project.name}' a été créé",
          notifiable: project,
          data: {
            project_id: project.id,
            project_name: project.name,
            created_by: project.created_by&.full_name
          }
        )
      end
    end

    def notify_project_updated(project, updated_by, changes = {})
      project.stakeholders.each do |stakeholder|
        next if stakeholder.user == updated_by
        
        Notification.notify_user(
          stakeholder.user,
          :project_updated,
          "Projet mis à jour",
          "Le projet '#{project.name}' a été mis à jour par #{updated_by.full_name}",
          notifiable: project,
          data: {
            project_id: project.id,
            updated_by: updated_by.full_name,
            changes: changes
          }
        )
      end
    end

    def notify_project_phase_completed(phase, completed_by)
      phase.project.stakeholders.each do |stakeholder|
        Notification.notify_user(
          stakeholder.user,
          :project_phase_completed,
          "Phase terminée",
          "La phase '#{phase.name}' du projet '#{phase.project.name}' a été terminée",
          notifiable: phase,
          data: {
            project_id: phase.project.id,
            phase_id: phase.id,
            completed_by: completed_by.full_name
          }
        )
      end
    end

    def notify_project_task_assigned(task, assigned_to, assigned_by)
      Notification.notify_user(
        assigned_to,
        :project_task_assigned,
        "Nouvelle tâche assignée",
        "#{assigned_by.full_name} vous a assigné la tâche '#{task.name}' dans le projet '#{task.phase.project.name}'",
        notifiable: task,
        data: {
          project_id: task.phase.project.id,
          phase_id: task.phase.id,
          task_id: task.id,
          assigned_by: assigned_by.full_name,
          due_date: task.due_date
        }
      )
    end

    def notify_project_task_completed(task, completed_by)
      task.phase.project.stakeholders.each do |stakeholder|
        next if stakeholder.user == completed_by
        
        Notification.notify_user(
          stakeholder.user,
          :project_task_completed,
          "Tâche terminée",
          "La tâche '#{task.name}' a été terminée par #{completed_by.full_name}",
          notifiable: task,
          data: {
            project_id: task.phase.project.id,
            phase_id: task.phase.id,
            task_id: task.id,
            completed_by: completed_by.full_name
          }
        )
      end
    end

    def notify_project_task_overdue(task)
      Notification.notify_user(
        task.assigned_to,
        :project_task_overdue,
        "Tâche en retard",
        "La tâche '#{task.name}' est en retard (échéance: #{task.due_date.strftime('%d/%m/%Y')})",
        notifiable: task,
        data: {
          project_id: task.phase.project.id,
          phase_id: task.phase.id,
          task_id: task.id,
          due_date: task.due_date,
          days_overdue: (Date.current - task.due_date).to_i
        }
      )
    end

    def notify_project_milestone_reached(milestone, project)
      project.stakeholders.each do |stakeholder|
        Notification.notify_user(
          stakeholder.user,
          :project_milestone_reached,
          "Jalon atteint",
          "Le jalon '#{milestone.name}' du projet '#{project.name}' a été atteint",
          notifiable: milestone,
          data: {
            project_id: project.id,
            milestone_id: milestone.id,
            achievement_date: milestone.actual_date
          }
        )
      end
    end

    def notify_project_deadline_approaching(project, days_remaining)
      project.stakeholders.each do |stakeholder|
        Notification.notify_user(
          stakeholder.user,
          :project_deadline_approaching,
          "Échéance approche",
          "L'échéance du projet '#{project.name}' approche (#{days_remaining} jours restants)",
          notifiable: project,
          data: {
            project_id: project.id,
            deadline: project.end_date,
            days_remaining: days_remaining
          }
        )
      end
    end

    # ImmoPromo Stakeholder Notifications
    def notify_stakeholder_assigned(stakeholder, project, assigned_by)
      Notification.notify_user(
        stakeholder.user,
        :stakeholder_assigned,
        "Assigné au projet",
        "#{assigned_by.full_name} vous a assigné au projet '#{project.name}' en tant que #{stakeholder.role}",
        notifiable: stakeholder,
        data: {
          project_id: project.id,
          stakeholder_id: stakeholder.id,
          role: stakeholder.role,
          assigned_by: assigned_by.full_name
        }
      )
    end

    def notify_stakeholder_approved(stakeholder, approved_by)
      Notification.notify_user(
        stakeholder.user,
        :stakeholder_approved,
        "Intervenant approuvé",
        "Votre participation au projet '#{stakeholder.project.name}' a été approuvée",
        notifiable: stakeholder,
        data: {
          project_id: stakeholder.project.id,
          stakeholder_id: stakeholder.id,
          approved_by: approved_by.full_name
        }
      )
    end

    def notify_stakeholder_rejected(stakeholder, rejected_by, reason = nil)
      Notification.notify_user(
        stakeholder.user,
        :stakeholder_rejected,
        "Intervenant rejeté",
        "Votre participation au projet '#{stakeholder.project.name}' a été rejetée",
        notifiable: stakeholder,
        data: {
          project_id: stakeholder.project.id,
          stakeholder_id: stakeholder.id,
          rejected_by: rejected_by.full_name,
          reason: reason
        }
      )
    end

    def notify_stakeholder_certification_expiring(stakeholder, days_remaining)
      Notification.notify_user(
        stakeholder.user,
        :stakeholder_certification_expiring,
        "Certification expire bientôt",
        "Votre certification expire dans #{days_remaining} jours",
        notifiable: stakeholder,
        data: {
          stakeholder_id: stakeholder.id,
          certification_expiry: stakeholder.certification_expiry,
          days_remaining: days_remaining
        }
      )
    end

    # ImmoPromo Permit Notifications
    def notify_permit_submitted(permit, submitted_by)
      permit.project.stakeholders.each do |stakeholder|
        Notification.notify_user(
          stakeholder.user,
          :permit_submitted,
          "Permis soumis",
          "Le permis '#{permit.name}' a été soumis pour le projet '#{permit.project.name}'",
          notifiable: permit,
          data: {
            project_id: permit.project.id,
            permit_id: permit.id,
            submitted_by: submitted_by.full_name,
            submission_date: permit.submission_date
          }
        )
      end
    end

    def notify_permit_approved(permit)
      permit.project.stakeholders.each do |stakeholder|
        Notification.notify_user(
          stakeholder.user,
          :permit_approved,
          "Permis approuvé",
          "Le permis '#{permit.name}' du projet '#{permit.project.name}' a été approuvé",
          notifiable: permit,
          data: {
            project_id: permit.project.id,
            permit_id: permit.id,
            approval_date: permit.approval_date
          }
        )
      end
    end

    def notify_permit_rejected(permit, reason = nil)
      permit.project.stakeholders.each do |stakeholder|
        Notification.notify_user(
          stakeholder.user,
          :permit_rejected,
          "Permis rejeté",
          "Le permis '#{permit.name}' du projet '#{permit.project.name}' a été rejeté",
          notifiable: permit,
          data: {
            project_id: permit.project.id,
            permit_id: permit.id,
            rejection_reason: reason
          }
        )
      end
    end

    def notify_permit_deadline_approaching(permit, days_remaining)
      permit.project.stakeholders.each do |stakeholder|
        Notification.notify_user(
          stakeholder.user,
          :permit_deadline_approaching,
          "Échéance permis approche",
          "L'échéance du permis '#{permit.name}' approche (#{days_remaining} jours restants)",
          notifiable: permit,
          data: {
            project_id: permit.project.id,
            permit_id: permit.id,
            deadline: permit.deadline,
            days_remaining: days_remaining
          }
        )
      end
    end

    def notify_permit_condition_fulfilled(condition, permit)
      permit.project.stakeholders.each do |stakeholder|
        Notification.notify_user(
          stakeholder.user,
          :permit_condition_fulfilled,
          "Condition de permis remplie",
          "La condition '#{condition.description}' du permis '#{permit.name}' a été remplie",
          notifiable: condition,
          data: {
            project_id: permit.project.id,
            permit_id: permit.id,
            condition_id: condition.id
          }
        )
      end
    end

    # ImmoPromo Budget Notifications
    def notify_budget_alert(budget, threshold_exceeded, current_percentage)
      budget.project.stakeholders.each do |stakeholder|
        Notification.notify_user(
          stakeholder.user,
          :budget_alert,
          "Alerte budget",
          "Le budget '#{budget.name}' du projet '#{budget.project.name}' a atteint #{current_percentage}% (seuil: #{threshold_exceeded}%)",
          notifiable: budget,
          data: {
            project_id: budget.project.id,
            budget_id: budget.id,
            threshold: threshold_exceeded,
            current_percentage: current_percentage
          }
        )
      end
    end

    def notify_budget_exceeded(budget, overage_amount)
      budget.project.stakeholders.each do |stakeholder|
        Notification.notify_user(
          stakeholder.user,
          :budget_exceeded,
          "Budget dépassé",
          "Le budget '#{budget.name}' du projet '#{budget.project.name}' a été dépassé de #{overage_amount}€",
          notifiable: budget,
          data: {
            project_id: budget.project.id,
            budget_id: budget.id,
            overage_amount: overage_amount
          }
        )
      end
    end

    def notify_budget_adjustment_requested(budget, requested_by, new_amount)
      budget.project.stakeholders.where(role: ['chef_projet', 'directeur']).each do |stakeholder|
        Notification.notify_user(
          stakeholder.user,
          :budget_adjustment_requested,
          "Ajustement budget demandé",
          "#{requested_by.full_name} demande un ajustement du budget '#{budget.name}' à #{new_amount}€",
          notifiable: budget,
          data: {
            project_id: budget.project.id,
            budget_id: budget.id,
            requested_by: requested_by.full_name,
            current_amount: budget.amount,
            requested_amount: new_amount
          }
        )
      end
    end

    def notify_budget_adjustment_approved(budget, approved_by, new_amount)
      budget.project.stakeholders.each do |stakeholder|
        Notification.notify_user(
          stakeholder.user,
          :budget_adjustment_approved,
          "Ajustement budget approuvé",
          "L'ajustement du budget '#{budget.name}' à #{new_amount}€ a été approuvé",
          notifiable: budget,
          data: {
            project_id: budget.project.id,
            budget_id: budget.id,
            approved_by: approved_by.full_name,
            previous_amount: budget.amount,
            new_amount: new_amount
          }
        )
      end
    end

    # ImmoPromo Risk Notifications
    def notify_risk_identified(risk, identified_by)
      risk.project.stakeholders.each do |stakeholder|
        Notification.notify_user(
          stakeholder.user,
          :risk_identified,
          "Nouveau risque identifié",
          "Un nouveau risque '#{risk.title}' a été identifié dans le projet '#{risk.project.name}'",
          notifiable: risk,
          data: {
            project_id: risk.project.id,
            risk_id: risk.id,
            severity: risk.severity,
            identified_by: identified_by.full_name
          }
        )
      end
    end

    def notify_risk_escalated(risk, escalated_by)
      risk.project.stakeholders.where(role: ['chef_projet', 'directeur']).each do |stakeholder|
        Notification.notify_user(
          stakeholder.user,
          :risk_escalated,
          "Risque escaladé",
          "Le risque '#{risk.title}' du projet '#{risk.project.name}' a été escaladé",
          notifiable: risk,
          data: {
            project_id: risk.project.id,
            risk_id: risk.id,
            severity: risk.severity,
            escalated_by: escalated_by.full_name
          }
        )
      end
    end

    def notify_risk_mitigation_required(risk, required_by)
      if risk.assigned_to
        Notification.notify_user(
          risk.assigned_to,
          :risk_mitigation_required,
          "Mitigation de risque requise",
          "Une action de mitigation est requise pour le risque '#{risk.title}'",
          notifiable: risk,
          data: {
            project_id: risk.project.id,
            risk_id: risk.id,
            severity: risk.severity,
            required_by: required_by.full_name
          }
        )
      end
    end

    def notify_risk_resolved(risk, resolved_by)
      risk.project.stakeholders.each do |stakeholder|
        Notification.notify_user(
          stakeholder.user,
          :risk_resolved,
          "Risque résolu",
          "Le risque '#{risk.title}' du projet '#{risk.project.name}' a été résolu",
          notifiable: risk,
          data: {
            project_id: risk.project.id,
            risk_id: risk.id,
            resolved_by: resolved_by.full_name,
            resolution_date: Date.current
          }
        )
      end
    end

    # System Notifications
    def notify_maintenance_scheduled(users, start_time, duration, description = nil)
      users.each do |user|
        Notification.notify_user(
          user,
          :maintenance_scheduled,
          "Maintenance programmée",
          "Une maintenance système est programmée le #{start_time.strftime('%d/%m/%Y à %H:%M')} (durée: #{duration})",
          data: {
            start_time: start_time,
            duration: duration,
            description: description
          }
        )
      end
    end
    
    def mark_all_read_for_user(user)
      Notification.mark_all_as_read_for(user)
    end
    
    def unread_count_for_user(user)
      Notification.unread.for_user(user).count
    end
    
    def recent_notifications_for_user(user, limit: 10)
      Notification.for_user(user).recent.limit(limit)
    end

    def notifications_by_category_for_user(user, category, limit: 20)
      Notification.for_user(user).by_category(category).recent.limit(limit)
    end

    def urgent_notifications_for_user(user)
      Notification.for_user(user).urgent.unread.recent
    end

    def mark_notification_as_read(notification_id, user)
      notification = Notification.for_user(user).find(notification_id)
      notification.mark_as_read!
      notification
    end

    def bulk_mark_as_read(notification_ids, user)
      notifications = Notification.for_user(user).where(id: notification_ids)
      notifications.update_all(read_at: Time.current)
      notifications.count
    end

    def delete_notification(notification_id, user)
      notification = Notification.for_user(user).find(notification_id)
      notification.destroy!
    end

    def bulk_delete_notifications(notification_ids, user)
      notifications = Notification.for_user(user).where(id: notification_ids)
      count = notifications.count
      notifications.destroy_all
      count
    end

    def notification_stats_for_user(user)
      notifications = Notification.for_user(user)
      {
        total: notifications.count,
        unread: notifications.unread.count,
        urgent: notifications.urgent.unread.count,
        today: notifications.today.count,
        this_week: notifications.this_week.count,
        by_category: Notification.categories.map do |category|
          [category, notifications.by_category(category).count]
        end.to_h
      }
    end
    
    private
    
    def authorizable_title(authorizable)
      if authorizable.respond_to?(:title)
        authorizable.title
      elsif authorizable.respond_to?(:name)
        authorizable.name
      else
        "##{authorizable.id}"
      end
    end
    
    def validatable_title(validatable)
      if validatable.respond_to?(:validatable_title)
        validatable.validatable_title
      elsif validatable.respond_to?(:title)
        validatable.title
      elsif validatable.respond_to?(:name)
        validatable.name
      else
        "#{validatable.class.name} ##{validatable.id}"
      end
    end
  end
end