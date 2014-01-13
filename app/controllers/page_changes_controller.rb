class PageChangesController < ApplicationController

  respond_to :html

  include RdfModule
  helper_method :get_rdf_json

  def diff
    page_change = PageChange.get_by_id params[:page_change_id]
    another_page_change = PageChange.get_by_id params[:another_page_change_id]

    if page_change.nil? and another_page_change.nil?
      flash[:warning] = 'Unfortunately diff cannot be displayed =/'
      go_to_previous_page and return
    end

    # both changes need to be not nil
    # if one is nil -> assume, that we are comparing version with current version
    page_change_is_nil = page_change.nil?

    @page = page_change_is_nil ? another_page_change.page : page_change.page

    if page_change_is_nil
      page_change = @page
    elsif another_page_change.nil?
      another_page_change = @page
    end

    @diff = PageChange.get_diff another_page_change.raw_content, page_change.raw_content

    # show title or 2 titles, if page was renamed
    @title = (page_change.title == another_page_change.title)?
        page_change.title : "#{page_change.title} => #{another_page_change.title}"

  end

  def apply
    page_change = PageChange.get_by_id params[:page_change_id]

    if page_change.nil?
      flash[:error] = "Applying the revision wasn't successful"
      go_to_previous_page and return
    end

    if cannot? :manage, page_change.page
      flash[:error] = "Not enough permissions for applying revision"
      go_to_previous_page and return
    end

    page = page_change.page

    history_track = nil
    if (page.title_changed? or page.namespace_changed? or page.raw_content_changed?)
      history_track = page.create_track current_user
    end

    applying_result = page.update_or_rename(page_change.title, page_change.raw_content, nil)

    flash[:warning] =  applying_result ? 'Restored page from revision' : 'Restoring was unsuccessful'

    # save track, if applying was successful
    if applying_result and !history_track.nil?
      history_track.save
    end

    redirect_to "/wiki/#{page.url}"

  end

  def show
    page_change = PageChange.get_by_id params[:page_change_id]

    if page_change.nil?
      flash[:error] = "Cannot show page with content of this revision"
      go_to_previous_page and return
    end

    @real_page = page_change.page

    @page = Page.new

    namespace_and_title = PageModule.retrieve_namespace_and_title page_change.title

    @page.title = namespace_and_title["title"]
    @page.namespace = namespace_and_title["namespace"]
    @page.raw_content = page_change.raw_content

    # do internal work with links e.t.c
    @page.preparing_the_page

  end

end