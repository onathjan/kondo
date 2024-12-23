module SiteMapGenerator
  require 'builder'
  require 'fileutils'
  require 'yaml'

  SITE_DIRECTORY = File.expand_path('../site', __dir__)
  BASE_URL = YAML.load_file("config/config.yaml")["site_url"]

  def self.generate
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
    xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
      Dir.glob("#{SITE_DIRECTORY}/**/*").each do |file|
        next if File.directory?(file)
        next if file.include?('/assets/')

        relative_path = file.sub("#{SITE_DIRECTORY}/", '')

        if relative_path == "index.html"
          url = BASE_URL
        else
          url = File.join(BASE_URL, relative_path)
        end

        xml.url do
          xml.loc url
          xml.lastmod File.mtime(file).iso8601
        end
      end
    end

    File.write("site/sitemap.xml", xml.target!)
  end
end
