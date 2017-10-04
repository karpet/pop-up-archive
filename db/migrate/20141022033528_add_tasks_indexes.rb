class AddTasksIndexes < ActiveRecord::Migration
  def up
    add_index :tasks, :type
    add_index :tasks, :status
    add_index :tasks, :created_at

    # custom hstore index
    execute "create index index_on_tasks_extras_entity_id on tasks using btree ( (extras->'entity_id') )"

  end

  def down
  end
end
