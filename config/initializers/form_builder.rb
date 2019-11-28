Rails.application.config.action_view.default_form_builder = GOVUKDesignSystemFormBuilder::FormBuilder

# Don't use XHR when submitting forms
Rails.application.config.action_view.form_with_generates_remote_forms = false
