Rails.application.config.action_view.default_form_builder = GOVUKDesignSystemFormBuilder::FormBuilder

# Don't use XHR when submitting forms
Rails.application.config.action_view.form_with_generates_remote_forms = false

# Use activerecord.attributes.model.attribute_name for label scope
module GOVUKDesignSystemFormBuilder
  class Base
    private def localised_text(context)
      key = localisation_key(context)

      return nil unless I18n.exists?(key)

      translation = I18n.translate(key)
      translation = translation.fetch(:html).html_safe if translation.is_a?(Hash) && translation.key?(:html)
      translation
    end

    private def localisation_key(context)
      return nil unless @object_name.present? && @attribute_name.present?

      if context == "label"
        ["activerecord", "attributes", @object_name, @attribute_name].join(".")
      else
        ["helpers", context, @object_name, @attribute_name].join(".")
      end
    end

    def has_errors?
      @builder.object.errors.any? &&
        @builder.object.errors.messages.dig(
          translated_attribute_name(attribute_name: @attribute_name)
        ).present?
    end

    # In order to support associations where the model association is
    # eg. `provider` but the form attribute needs to be `provider_id`.
    # The form field must be wrapped in errors and be linkable from the summary.
    #
    # 1. We cannot change the form field to `provider` since the value will
    # not read from an object with a value already set.
    #
    # 2. We cannot change the model association to be `provider_id` as calling
    # `transaction.provider_id` rather than the resource  `transaction.provider`
    # would be unconventional and also require a hack.
    #
    # 3. We cannot overwride the @attribute_name on create since that will have
    # the same affect as point 1.
    private def translated_attribute_name(attribute_name:)
      translations = @builder.object.class.try("::FORM_FIELD_TRANSLATIONS") || {}

      if translations[attribute_name].present?
        translations[attribute_name]
      else
        attribute_name
      end
    end
  end
end

module GOVUKDesignSystemFormBuilder
  module Elements
    class Select < GOVUKDesignSystemFormBuilder::Base
      def error_element
        @error_element ||= Elements::ErrorMessage.new(
          @builder,
          @object_name,
          translated_attribute_name(attribute_name: @attribute_name)
        )
      end

      def field_id(link_errors: false)
        if link_errors && has_errors?
          build_id(
            "field-error",
            include_value: false,
            attribute_name: translated_attribute_name(attribute_name: @attribute_name)
          )
        else
          build_id("field")
        end
      end
    end

    module Radios
      class CollectionRadioButton < GOVUKDesignSystemFormBuilder::Base
        def field_id(link_errors: false)
          if link_errors && has_errors?
            build_id(
              "field-error",
              include_value: false,
              attribute_name: translated_attribute_name(attribute_name: @attribute_name)
            )
          else
            build_id("field")
          end
        end
      end
    end
  end
end
