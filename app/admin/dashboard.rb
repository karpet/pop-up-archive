ActiveAdmin.register_page "Dashboard" do

  menu :priority => 1, :label => proc{ I18n.t("active_admin.dashboard") }

  content :title => proc{ I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel "Recent Collections" do
          table do
            Collection.order('created_at DESC').limit(20).map do |coll|
              tr do
                td link_to(coll.title, superadmin_collection_path(coll))
                td coll.creator ? link_to(coll.creator.name, superadmin_user_path(coll.creator)) : '(empty)'
              end 
            end
          end
        end
      end # column one
      column do
        panel "Info" do
          para "Welcome to Pop Up Archive SuperAdmin section."
        end
      end # column two
    end
  end

end
