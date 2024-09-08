class CreateNotificationSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :notification_settings do |t|
      t.string :trigger_type, null: false
      t.jsonb :media, null: false

      t.timestamps
    end

    add_index :notification_settings, :trigger_type, unique: true
  end
end
