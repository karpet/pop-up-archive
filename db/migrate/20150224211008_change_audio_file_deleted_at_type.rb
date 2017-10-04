class ChangeAudioFileDeletedAtType < ActiveRecord::Migration
  def up
    time_to_timestamp(:audio_files, :deleted_at)
  end

  def down
    change_table :audio_files do |t|
      t.change :deleted_at, :time
    end
  end

  def time_to_timestamp(tbl, col)
    add_column tbl, "#{col}_t2t_tmp", :timestamp
    execute "update #{tbl} set #{col}_t2t_tmp = (date '2015-02-24 ' + #{col}) where #{col} is not null"
    remove_column tbl, col 
    rename_column tbl, "#{col}_t2t_tmp", col 
  end
end
