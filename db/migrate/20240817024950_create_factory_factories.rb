class CreateFactoryFactories < ActiveRecord::Migration[7.2]
  def change
    create_table :factory_factories do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
