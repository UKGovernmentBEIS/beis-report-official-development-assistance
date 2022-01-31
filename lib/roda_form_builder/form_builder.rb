module RodaFormBuilder
  class FormBuilder < GOVUKDesignSystemFormBuilder::FormBuilder
    include ApplicationHelper

    def with_guidance(attribute_name, html)
      return if html.nil?

      guidance_url = GuidanceUrl.new(@object_name, attribute_name).to_s

      if guidance_url.present?
        doc = Nokogiri::HTML.fragment(html)

        doc.xpath("div").first.add_child(content_tag(:p, class: "guidance") {
          [
            "For help responding to this question, refer to the",
            link_to_new_tab("guidance", guidance_url)
          ].join(" ").html_safe
        })

        html = doc.to_s.html_safe
      end

      html
    end

    [
      :govuk_text_field,
      :govuk_phone_field,
      :govuk_email_field,
      :govuk_password_field,
      :govuk_url_field,
      :govuk_number_field,
      :govuk_text_area,
      :govuk_collection_select,
      :govuk_collection_radio_buttons,
      :govuk_collection_check_boxes,
      :govuk_date_field
    ].each do |method|
      define_method(method) do |attribute_name, *args, &block|
        with_guidance(attribute_name, super(attribute_name, *args))
      end
    end
  end
end
