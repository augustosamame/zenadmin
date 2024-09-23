class CreateUserAttendanceLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :user_attendance_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true
      t.datetime :checkin
      t.datetime :checkout
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
