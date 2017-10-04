ActiveAdmin.register Person do
  actions :index, :show
  index do
    column :name, sortable: :name do |person|
      link_to( person.name, superadmin_person_path(person) )
    end
    column :slug
  end

  filter :name
  filter :slug

  show do
    panel "Person Details" do
      attributes_table_for person do
        row("ID") { person.id }
        row("Name") { person.name }
        row("Slug") { person.slug }
        row("Created") { person.created_at }
        row("Updated") { person.updated_at }
      end
    end

    panel "Items" do
      table_for person.items do|tbl|
        tbl.column("Title") {|i| link_to i.title, superadmin_item_path(i) }
        tbl.column("Collection") {|i| link_to i.collection.title, superadmin_collection_path(i.collection) }
      end
    end

    active_admin_comments
  end

end
