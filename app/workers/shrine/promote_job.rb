class Shrine::PromoteJob
  include Sidekiq::Worker

  def perform(attacher_class_name, record_class_name, record_id, name, file_data_json)
    # Convert class names from strings to constants
    attacher_class = Object.const_get(attacher_class_name)
    record_class   = Object.const_get(record_class_name)

    # Retrieve the record using the record_id
    record = record_class.find(record_id)

    # Deserialize file_data from JSON string to hash
    file_data = JSON.parse(file_data_json)

    # Retrieve the attacher
    attacher = attacher_class.retrieve(model: record, name: name, file: file_data)

    # Perform the promotion tasks
    attacher.create_derivatives
    attacher.atomic_promote
  rescue Shrine::AttachmentChanged, ActiveRecord::RecordNotFound
    # The attachment has changed or the record has been deleted, nothing to do
  end
end
