class GetInitialPageContent
  include SolidUseCase
  steps(
    GetValidationStatusForPage,
    :choose_template,
    :create_page_content,
    )

    def choose_template(params)
      templates = params[:templates]
      # TODO: let this be parameter-dependent
      params[:template] = templates.first

      continue(params)
    end

    def create_page_content(params)
      validator = params[:validator]
      template = params[:template]
      page = validator.page
      new_page = validator.generate_page(template, page)
      params[:page].raw_content = new_page.raw_content

      continue(params)
    end

end
