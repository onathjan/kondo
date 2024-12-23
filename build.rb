require_relative 'lib/rss_generator'
require_relative 'lib/site_builder'
require_relative 'lib/site_map_generator'

def build_site
  SiteBuilder.build_index_page
  SiteBuilder.build_pages
  SiteMapGenerator.generate
  RssGenerator.generate
end
