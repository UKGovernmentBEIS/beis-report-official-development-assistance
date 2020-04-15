require "singleton"

module PublicActivity
  # Class used to initialize configuration object.
  class Config
    include ::Singleton

    def self.table_name(name = nil)
      if name.nil?
        Thread.current[:public_activity_table_name] || "auditable_events"
      else
        Thread.current[:public_activity_table_name] = name
      end
    end
  end
end

PublicActivity::Config.set do
  table_name "auditable_events"
end
