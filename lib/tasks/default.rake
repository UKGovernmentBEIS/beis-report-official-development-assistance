task(:default).clear_prerequisites.enhance(%i[standard spec]) if Rails.env.test? || Rails.env.development?
