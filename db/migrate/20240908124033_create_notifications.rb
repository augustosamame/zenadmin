class CreateNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications do |t|
      t.references :notifiable, polymorphic: true, null: false
      t.integer :medium, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.integer :severity, null: false, default: 0
      t.text :message_title
      t.text :message_body, null: false
      t.text :message_image
      t.datetime :read_at
      t.datetime :clicked_at
      t.datetime :opened_at

      t.timestamps
    end
  end
end
