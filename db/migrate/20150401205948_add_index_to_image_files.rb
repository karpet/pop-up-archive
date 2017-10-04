class AddIndexToImageFiles < ActiveRecord::Migration
  def change
    add_index :image_files, :imageable_id
    add_index :image_files, :imageable_type
  end
end
