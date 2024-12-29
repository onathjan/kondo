module RssGenerator
  require 'rss'
  require 'yaml'
  require_relative 'content_processor'

  def self.get_posts
    published_posts_front_matter = []
    Dir.glob("content/posts/*md").each do |file|
      front_matter, _ = ContentProcessor.read_front_matter(file)
      unless front_matter['draft'] == true
        published_posts_front_matter << front_matter
      end
    end

    published_posts_front_matter
  end

  def self.generate
    config_file = YAML.load_file("config/config.yaml")
    posts = self.get_posts

    rss = RSS::Maker.make("2.0") do |maker|
      maker.channel.title = config_file["site_name"]
      maker.channel.link = config_file["site_url"]
      maker.channel.description = config_file["site_description"]

      posts.each do |post|
        maker.items.new_item do |item|
          item.title = post["title"]
          item.link = "#{config_file["site_url"]}/#{post["slug"]}.html"
          item.description = post["description"]
          item.pubDate = post["date"]
          item.guid.content = "#{config_file["site_url"]}/#{post["slug"]}.html"
        end
      end
    end

    rss_xml = rss.to_s
    rss_xml.gsub!(/xmlns:itunes="http:\/\/www.itunes.com\/dtds\/podcast-1.0.dtd"\s*/, "")
    File.write('site/rss.xml', rss_xml)
  end
end
