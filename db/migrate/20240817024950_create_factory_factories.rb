class CreateFactoryFactories < ActiveRecord::Migration[7.2]
  def change
    create_table :factory_factories do |t|
      t.string :name, null: false
      t.references :region, null: false, foreign_key: true
      t.timestamps
    end
  end
end
