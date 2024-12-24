module SiteMapGenerator
  require 'builder'
  require 'digest'
  require 'fileutils'
  require 'yaml'

  SITE_DIRECTORY = File.expand_path('../site', __dir__)
  BASE_URL = YAML.load_file("config/config.yaml")["site_url"]
  HASH_FILE = File.expand_path("../config/file_hashes.yaml", __dir__)

  def self.generate
    if File.exist?(HASH_FILE)
      existing_hashes = YAML.load_file(HASH_FILE)
    else
      existing_hashes = {}
    end

    new_hashes = {}

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

        content = File.read(file)
        file_hash = Digest::SHA256.hexdigest(content)
        new_hashes[relative_path] = file_hash

        if existing_hashes[relative_path] == file_hash
          lastmod = existing_hashes.fetch("#{relative_path}_lastmod", File.mtime(file).iso8601)
        else
          lastmod = Time.now.iso8601
        end

        new_hashes["#{relative_path}_lastmod"] = lastmod

        xml.url do
          xml.loc url
          xml.lastmod lastmod
        end
      end
    end

    File.write("site/sitemap.xml", xml.target!)

    File.write(HASH_FILE, new_hashes.to_yaml)
  end
end
