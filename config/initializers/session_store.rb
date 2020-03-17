Rails.application.config.session_store :active_record_store,
  key: "_roda_session",
  expire_after: 12.hours
