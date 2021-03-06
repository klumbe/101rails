# class PageRepo
#   include PageBuilder
#
#   def initialize
#
#   end
#
#   def get(namespace, title)
#     underscore_title = title.gsub(' ', '_')
#     page = Page.where(namespace: namespace, title: [title, underscore_title]).first
#     build_page_entity(page)
#   end
#
#   def by_author(user)
#     Page
#       .where('used_links && ARRAY[?]::varchar[]', "developedBy::Contributor:#{user.github_name}/")
#       .map { |page| build_page_entity(page) }
#   end
#
#   def used_predicates
#     Page.connection.execute('
#       SELECT DISTINCT substr(link, 0, pos) as predicate
#       FROM pages, unnest(used_links) AS link, strpos(link, \'::\') AS pos
#       WHERE pos > 0 order by predicate
#     ').values.map { |row| row[0] }
#   end
#
#   def backlinking_pages
#     result = Page.where('used_links && ARRAY[?]::varchar[]', full_title)
#
#     nt = PageModule.retrieve_namespace_and_title(full_title)
#     if nt['namespace'] == 'Concept'
#       result = result.or(Page.where('used_links && ARRAY[?]::varchar[]', nt['title']))
#     end
#
#     result.map { |page| build_page_entity(page) }
#   end
#
#   def search(text)
#     like = Page.send(:sanitize_sql_like, text.downcase)
#     like = "%#{like}%"
#     pages = Page.where('LOWER(title) like ? or LOWER(raw_content) like ? or (namespace || \':\' || title) = ?', like, like, text).distinct
#     pages.map { |page| build_page_entity(page) }
#   end
#
#   def search_title(text)
#     like = Page.send(:sanitize_sql_like, text.downcase)
#     like = "%#{like}%"
#     result = Page.where('LOWER(title) like ? or (namespace || \':\' || title) = ?', like, text).distinct
#     result.map { |page| build_page_entity(page)  }
#   end
#
#   def self.recently_updated
#     Page.order(updated_at: :desc).limit(5)
#   end
#
# end
