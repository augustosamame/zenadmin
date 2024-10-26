class CreateUserSellerPhotos < ActiveRecord::Migration[7.2]
  def change
    create_table :user_seller_photos do |t|
      t.references :user, null: false, foreign_key: true
      t.text :seller_photo
      t.string :aws_rekognition_face_id

      t.timestamps
    end
  end
end
