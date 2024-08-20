class Shrine::DestroyJob
  include Sidekiq::Worker

  def perform(attacher_class, file_data)
    attacher_class = Object.const_get(attacher_class)

    attacher = attacher_class.from_data(data)
    attacher.destroy
  end
end
