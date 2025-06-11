class Api::TasksController < Api::BaseController
  def index
    # Placeholder - dans une vraie app, on aurait un modèle Task
    render_json({
      tasks: [
        {
          id: 1,
          title: "Exemple de tâche",
          status: "pending",
          created_at: Time.current
        }
      ]
    })
  end
end