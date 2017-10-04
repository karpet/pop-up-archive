class TimedTextToDecimal < ActiveRecord::Migration
  def up
    change_column :timed_texts, :start_time, :decimal
    change_column :timed_texts, :end_time, :decimal
  end

  def down
    change_column :timed_texts, :start_time, :integer
    change_column :timed_texts, :end_time, :integer
  end
end
