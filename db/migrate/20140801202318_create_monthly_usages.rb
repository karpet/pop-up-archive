class CreateMonthlyUsages < ActiveRecord::Migration
  def change
    create_table :monthly_usages do |t|

      t.references :entity, polymorphic: true

      t.string :use

      t.integer :month
      t.integer :year

      t.decimal :value

      t.timestamps
    end

    add_index :monthly_usages, [:entity_id, :entity_type]
    add_index :monthly_usages, [:entity_id, :entity_type, :use]
    add_index :monthly_usages, [:entity_id, :entity_type, :use, :month, :year], name: 'index_entity_use_date'

  end
end
