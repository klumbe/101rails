class PagesController < ApplicationController
  include RdfModule

  before_action :set_default_response_format, only: [:index]
  after_action :set_last_page

  # for calling from view
  helper_method :get_rdf_json

  # before_filter need to be before load_and_authorize_resource
  # methods, that need to check permissions
  before_action :get_the_page, only: [:edit, :rename, :update, :update_repo, :destroy, :validate]
  before_action :get_validation_result, only: [:validate]
  authorize_resource only: [:delete, :rename, :update, :apply_findings, :update_repo, :render_script]

  def get_the_page
    full_title = params[:id]

    @page = GetPage.run(full_title: full_title).value[:page]
    # if page doesn't exist, but it's user page -> create page and redirect
    if @page.nil? && !current_user.nil? && full_title.downcase=="Contributor:#{current_user.github_name}".downcase
      PageModule.create_page_by_full_title(full_title)
      redirect_to page_path(full_title) and return
    end
    # page not found and user can create page -> create new page by full_title
    if @page.nil? && (can? :create, Page.new)
      redirect_to create_new_page_confirmation_page_path(full_title)
      return
    end
    # if no page created/found
    if !@page
      return respond_to do |format|
        format.html do
          flash[:error] = "Page wasn't not found. Redirected to main wiki page"
          go_to_homepage
        end
        format.json {
          return render json: {success: false}, status: 404
        }
      end
    end

    # get rdf
    @rdf = get_rdf_json(@page.full_title, true)

    @rdf = @rdf.sort do |x,y|
      if x[:predicate] == y[:predicate]
        x[:node] <=> y[:node]
      else
        x[:predicate] <=> y[:predicate]
      end
    end

    @resources = @rdf.select do |triple|
      (triple[:node].start_with?('http://') || triple[:node].starts_with?('https://'))
    end

    @rdf = @rdf.select do |triple|
      !(triple[:node].start_with?('http://') || triple[:node].start_with?('https://'))
    end

    @books = []
  end

  def get_validation_result
    if @page.nil? || @page.namespace == 'Template'
      @validation_status_list = []
      @valid = false
    else
      @validation_status_list = GetValidationStatusForPage.run(page: @page).value[:status]
      @valid = ((@validation_status_list.select {|s| !s.valid?}.empty?) && !@validation_status_list.empty?)
    end
  end

  def index
    if params[:after_id]
      @pages = Page.where('id > ?', params[:after_id]).includes(:triples)
    else
      @pages = Page.includes(:triples).all
    end
    @pages = @pages.order(:id).limit(500)
  end

  def unverify
    if (cannot? :unverify, Page)
      flash[:error] = "You don't have enough rights for that."
      go_to_homepage and return
    end

    UnverifyPage.run(user_id: current_user.id, page_id: params[:id], full_title: params[:id]).match do

      failure(:page_already_unverified) do
        flash[:error] = "Page is already unverified."
        go_to_homepage
      end

      success do
        flash[:notice] = 'Page is unverified now.'
        redirect_to(page_path(params[:id]))
      end

    end
  end

  def verify
    if (cannot? :verify, Page)
      flash[:error] = "You don't have enough rights for that."
      go_to_homepage and return
    end

    VerifyPage.run(user_id: current_user.id, page_id: params[:id], full_title: params[:id]).match do

      failure(:page_already_verified) do
        flash[:error] = "Page is already verified."
        go_to_homepage
      end

      success do
        flash[:notice] = 'Page is verified now.'
        redirect_to(page_path(params[:id]))
      end

    end

  end

  def unverified
    if (cannot? :list, :unverified_pages)
      flash[:error] = "You don't have enough rights for that."
      go_to_homepage and return
    end

    ListUnverifiedPages.run.match do

      success do |result|
        @pages = result[:pages]
      end

    end
  end

  def create_new_page
    if (cannot? :create, Page.new)
      flash[:error] = "You don't have enough rights for creating the page."
      go_to_homepage and return
    end

    full_title = params[:id]
    page = PageModule.create_page_by_full_title(full_title)
    if page
      if page.namespace != 'Template'
        GenerateInitialPageContent.run(page: page)
        page.save
      end
      redirect_to page_path(full_title) and return
    else
      flash[:error] = "You cannot create new page #{full_title}"
      redirect_to page_path('101project') and return
    end
  end

  def create_new_page_confirmation
    @full_title = params[:id]
  end

  def update_repo
    repo_link = params[:repo_link]
    # if no link to repo -> create it
    if @page.repo_link.nil?
      @page.repo_link = RepoLink.new
    end
    # fill props
    @page.repo_link.folder = repo_link[:folder]
    @page.repo_link.user = repo_link[:user_repo].split('/').first
    @page.repo_link.repo = repo_link[:user_repo].split('/').last
    # assign page
    @page.repo_link.page = @page
    # save page and link
    (@page.save and @page.repo_link.save) ?
      flash[:success]="Updated linked repo" : flash[:error] = "Failed to update linked repo"
    redirect_to page_path(@page.url)
  end

  def edit
    @predicates = Triple.pluck(:predicate).uniq
  end

  def destroy
    authorize! :destroy, @page

    result = @page.destroy
    respond_to do |format|
      format.html { redirect_to page_path('101project'), notice: "Page #{@page.full_title} was deleted" }
    end
  end

  def show
    args = {
      full_title: params[:id],
      current_user: current_user,
      time: params[:time]
    }

    ShowPage.run(args).match do

      success do |result|
        @similarities   = result[:similarities]
        @page           = result[:page]
        @books          = result[:books]
        @rdf            = result[:triples]
        @resources      = result[:resources]
        @contributions  = result[:contributions]
        @errors         = result[:errors]
        @warnings       = result[:warnings]
        get_validation_result()
      end

      failure(:page_not_found) do |result|
        flash[:error] = "Page wasn't not found. Redirected to main wiki page"
        go_to_homepage
      end

      failure(:bad_link) do |result|
        redirect_to page_path(result[:url])
      end

      failure(:page_not_found_but_creating) do |result|
        redirect_to create_new_page_confirmation_page_path(result[:full_title])
      end

      failure(:contributor_page_created) do |result|
        redirect_to page_path(result[:full_title])
      end
    end
  end

  # get :full_title/validate
  def validate
    # unfolds the top accordion-view
    @unfolded = true

    respond_to do |format|
      format.html do
        render :validation_report
      end
      format.json do
        render json: @validation_status_list.to_json
      end
    end
  end

  def search
    @query_string = params[:q]
    @title_only = params[:title_only]
    if @query_string.present?
      if params.dig(:namespace, :name) == 'Property'
        @search_results = PageModule.search_property(@query_string)
      else
        @search_results = PageModule.search(@query_string, namespace: params.dig(:namespace, :name))
      end
    else
      if params.dig(:namespace, :name)
        @search_results = Page.where(namespace: params.dig(:namespace, :name)).order(:title)
      else
        @search_results = Page.none
      end
    end

    respond_to :html
  end

  def rename
    new_name = PageModule.unescape_wiki_url params[:newTitle]
    result = @page.update_or_rename(new_name, @page.raw_content, [], current_user)

    respond_to do |format|
      format.html { redirect_to page_path(new_name), notice: "Page #{params[:id]} was renamed to #{new_name}." }
    end
  end

  def update
    result = @page.update_or_rename(@page.full_title, params[:content], [], current_user)
    render json: {
      success: result,
      newTitle: @page.url
    }
  end

  protected

  def set_default_response_format
    request.format = :json
  end

  def set_last_page
    if @page
      session[:last_page] = @page.full_title
    end
  end

end
