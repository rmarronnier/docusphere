module NotificationService::ProjectNotifications
    extend ActiveSupport::Concern
    
    class_methods do
      def notify_project_created(project, stakeholders = [])
        # Notifier le project manager
        if project.project_manager
          Notification.notify_user(
            project.project_manager,
            :project_created,
            "Nouveau projet créé",
            "Le projet '#{project.name}' a été créé",
            notifiable: project,
            data: {
              project_id: project.id,
              project_name: project.name
            }
          )
        end
        
        # Notifier les stakeholders
        stakeholders.each do |stakeholder|
          next unless stakeholder.user
          
          Notification.notify_user(
            stakeholder.user,
            :project_assigned,
            "Assigné à un nouveau projet",
            "Vous avez été assigné au projet '#{project.name}'",
            notifiable: project,
            data: {
              project_id: project.id,
              project_name: project.name,
              role: stakeholder.role
            }
          )
        end
      end
      
      def notify_project_updated(project, updated_by, changes = {})
        project.stakeholders.joins(:user).each do |stakeholder|
          next if stakeholder.user == updated_by
          
          Notification.notify_user(
            stakeholder.user,
            :project_updated,
            "Projet mis à jour",
            "Le projet '#{project.name}' a été mis à jour par #{updated_by.full_name}",
            notifiable: project,
            data: {
              project_id: project.id,
              project_name: project.name,
              updated_by_id: updated_by.id,
              changes: changes
            }
          )
        end
      end
      
      def notify_project_phase_completed(phase, completed_by)
        project = phase.project
        
        # Notifier le project manager
        if project.project_manager && project.project_manager != completed_by
          Notification.notify_user(
            project.project_manager,
            :phase_completed,
            "Phase terminée",
            "La phase '#{phase.name}' du projet '#{project.name}' a été terminée",
            notifiable: phase,
            data: {
              phase_id: phase.id,
              phase_name: phase.name,
              project_id: project.id,
              project_name: project.name,
              completed_by_id: completed_by.id
            }
          )
        end
      end
      
      def notify_project_task_assigned(task, assigned_to, assigned_by)
        return if assigned_to == assigned_by
        
        Notification.notify_user(
          assigned_to,
          :task_assigned,
          "Nouvelle tâche assignée",
          "#{assigned_by.full_name} vous a assigné la tâche '#{task.name}'",
          notifiable: task,
          data: {
            task_id: task.id,
            task_name: task.name,
            project_name: task.phase.project.name,
            assigned_by_id: assigned_by.id,
            due_date: task.end_date
          }
        )
      end
      
      def notify_project_task_completed(task, completed_by)
        project = task.phase.project
        
        # Notifier le project manager si différent
        if project.project_manager && project.project_manager != completed_by
          Notification.notify_user(
            project.project_manager,
            :task_completed,
            "Tâche terminée",
            "La tâche '#{task.name}' a été terminée par #{completed_by.full_name}",
            notifiable: task,
            data: {
              task_id: task.id,
              task_name: task.name,
              project_name: project.name,
              completed_by_id: completed_by.id,
              completion_date: task.completed_date
            }
          )
        end
        
        # Notifier les stakeholders intéressés
        task.stakeholder&.user&.tap do |stakeholder_user|
          next if stakeholder_user == completed_by
          
          Notification.notify_user(
            stakeholder_user,
            :task_completed,
            "Tâche assignée terminée",
            "La tâche '#{task.name}' que vous supervisiez a été terminée",
            notifiable: task,
            data: {
              task_id: task.id,
              task_name: task.name,
              project_name: project.name,
              completed_by_id: completed_by.id
            }
          )
        end
      end
      
      def notify_project_task_overdue(task)
        if task.assigned_to
          Notification.notify_user(
            task.assigned_to,
            :task_overdue,
            "Tâche en retard",
            "La tâche '#{task.name}' est en retard (échéance: #{task.end_date.strftime('%d/%m/%Y')})",
            notifiable: task,
            data: {
              task_id: task.id,
              task_name: task.name,
              project_name: task.phase.project.name,
              due_date: task.end_date,
              days_overdue: (Date.current - task.end_date).to_i
            }
          )
        end
      end
      
      def notify_project_milestone_reached(milestone, project)
        project.stakeholders.joins(:user).each do |stakeholder|
          Notification.notify_user(
            stakeholder.user,
            :milestone_reached,
            "Jalon atteint",
            "Le jalon '#{milestone.name}' du projet '#{project.name}' a été atteint",
            notifiable: milestone,
            data: {
              milestone_id: milestone.id,
              milestone_name: milestone.name,
              project_id: project.id,
              project_name: project.name,
              achievement_date: milestone.actual_date
            }
          )
        end
      end
      
      def notify_project_deadline_approaching(project, days_remaining)
        if project.project_manager
          Notification.notify_user(
            project.project_manager,
            :deadline_approaching,
            "Échéance proche",
            "Le projet '#{project.name}' arrive à échéance dans #{days_remaining} jours",
            notifiable: project,
            data: {
              project_id: project.id,
              project_name: project.name,
              expected_completion_date: project.expected_completion_date,
              days_remaining: days_remaining
            }
          )
        end
      end
    end
end