Rails.application.config.action_view.default_form_builder = GOVUKDesignSystemFormBuilder::FormBuilder

# Don't use XHR when submitting forms
Rails.application.config.action_view.form_with_generates_remote_forms = false

# Use activerecord.attributes.model.attribute_name for label scope
module GOVUKDesignSystemFormBuilder
  class Base
    private def localisation_key(context)
      return nil unless @object_name.present? && @attribute_name.present?

      if context == "label"
        ["activerecord", "attributes", @object_name, @attribute_name].join(".")
      else
        ["helpers", context, @object_name, @attribute_name].join(".")
      end
    end
  end
end
