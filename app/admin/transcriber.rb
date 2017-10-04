ActiveAdmin.register Transcriber do
  actions :index, :show
  menu false
  index do
    column :id
    column :name
    column :url
    column :cost_per_min
    column :created_at
  end

  show do 
    panel "Transcriber Details" do
      attributes_table_for transcriber do
        row :id
        row :name
        row("Cost Per Min") { sprintf("$%0.3f", transcriber.cost_per_min.to_f / 1000) }
        row :created_at
        row :updated_at
        row :url
        row :description 
      end     
    end
 
    active_admin_comments
  end

end
