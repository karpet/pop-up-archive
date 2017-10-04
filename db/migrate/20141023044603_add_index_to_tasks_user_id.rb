class AddIndexToTasksUserId < ActiveRecord::Migration
  def change
    execute "create index index_on_tasks_extras_user_id on tasks using btree ( (extras->'user_id') )"
  end
end
