module RssGenerator
  require 'rss'
  require 'yaml'

  def self.generate(posts, output_path)
    config_file = YAML.load_file("config/config.yaml")
    
    rss = RSS::Maker.make("2.0") do |maker|
      maker.channel.title = config_file["site_name"]
      maker.channel.link = config_file["site_url"]
      maker.channel.description = config_file["site_description"]

      posts.each do |post|
        maker.items.new_item do |item|
          item.title = post[:title]
          item.link = post[:url]
          item.pubDate = post[:date]
        end
      end
    end
    File.write(output_path, rss)
  end
end
