class AddIndexToCharges < ActiveRecord::Migration
  def change
    add_index :charges, :ref_id
  end
end
