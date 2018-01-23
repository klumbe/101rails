class GetValidationStatusForPage
  include SolidUseCase

  steps(
    :create_validator,
    :fetch_templates,
    :fetch_default_templates,
    :add_templates_to_validator,
    :validate_page
  )

  def create_validator(params)
    page = params[:page]

    validator = WikiValidator::WikiValidator.new()
    page_dto = WikiValidator::PageDTO.new(page.title, page.namespace, page.raw_content)
    validator.set_page(page_dto)
    params[:validator] = validator

    continue(params)
  end

  def fetch_templates(params)
    validator = params[:validator]

    template_names = validator.extract_template_names()
    templates = []
    template_names.each do |full_title|
      template = GetPage.run(full_title: full_title).value[:page]
      if !template.nil?
        templates << WikiValidator::PageDTO.new(template.title,
                                                template.namespace,
                                                template.raw_content
                                               )
      end
    end

    params[:templates] = templates

    continue(params)
  end

  def fetch_default_templates(params)
    namespace = params[:page].namespace
    templates = params[:templates]
    validator = params[:validator]

    basic = 'Template:Basic'
    # select templates that inherit frome the pages namespace-template
    list = templates.select {|t| t.name.start_with?(namespace) }
    if list.empty?
      #  add the namespace template if it exists
      default_template = GetPage.run(full_title: "Template:#{namespace}").value[:page]
      if default_template.nil?
        default_template = GetPage.run(full_title: basic).value[:page]
      end
      if !default_template.nil?
        default_template_dto = WikiValidator::PageDTO.new(default_template.title,
                                                          default_template.namespace,
                                                          default_template.raw_content
                                                        )
        templates << default_template_dto
      end
    end

    continue(params)
  end

  def add_templates_to_validator(params)
    validator = params[:validator]
    templates = params[:templates]
    validator.add_templates(templates)

    continue(params)
  end

  def validate_page(params)
    validator = params[:validator]

    status = validator.validate()

    params[:status] = status
    continue(params)
  end

end
