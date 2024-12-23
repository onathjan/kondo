module SiteMapGenerator
  require 'builder'

  def self.generate(pages, output_path)
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
    xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
      pages.each do |page|
        xml.url do
          xml.loc page[:url]
          xml.lastmod page[:lastmod]
        end
      end
    end
    File.write(output_path, xml.target!)
  end
end
