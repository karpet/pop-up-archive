class AddImageableToImageFiles < ActiveRecord::Migration
  def up
    change_table :image_files do |t|
      t.references :imageable, :polymorphic => true
    end
  end

  def down
    change_table :image_files do |t|
      t.remove_references :imageable, :polymorphic => true
    end
  end
end
