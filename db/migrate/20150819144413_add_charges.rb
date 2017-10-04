class AddCharges < ActiveRecord::Migration
  def change
    create_table :charges do |t|
      t.references :user
      t.string :ref_id
      t.string :ref_type
      t.decimal :amount
      t.timestamp :transaction_at
      t.hstore :extras
      t.timestamps null: true
    end
  end
end
