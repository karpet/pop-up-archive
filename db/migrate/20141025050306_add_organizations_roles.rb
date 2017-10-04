class AddOrganizationsRoles < ActiveRecord::Migration
  def change 
    create_table(:organizations_roles, :id => false) do |t|
      t.references :organization
      t.references :role
    end
    add_index(:organizations_roles, [ :organization_id, :role_id ])
  end
end
