class Shrine::DestroyJob
  include Sidekiq::Worker

  def perform(attacher_class_name, file_data_json)
    # Convert class name from string to constant
    attacher_class = Object.const_get(attacher_class_name)

    # Deserialize the file_data from JSON string to hash
    file_data = JSON.parse(file_data_json)

    # Create the attacher from the data
    attacher = attacher_class.from_data(file_data)

    # Perform the destroy task
    attacher.destroy
  end
end
