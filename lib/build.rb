require 'fileutils'
require 'htmlbeautifier'
require 'kramdown'
require 'yaml'

config_file = YAML.load_file("config.yml")
SITE_NAME = config_file["site-name"]

def build_index_page
  posts = []

  Dir.glob("content/posts/*md").each do |file|
    front_matter, _ = read_front_matter(file)
    year = file[14..17]
    date = file[14..23]
    title = front_matter['title']
    slug = front_matter['slug'] + ".html" 
    draft = front_matter['draft']
    posts << { year: year, date: date, title: title, slug: slug } unless draft
  end

  post_years = []
  posts.each { |post| post_years << post.values.first }
  post_years.uniq!

  posts.sort_by! { |post| post[:date] }.reverse!

  blog_content = <<~BLOG
    ---
    title: Home
    slug: index
    ---
  
  BLOG

  post_years.reverse.each do |year|
    blog_content << "## #{year}\n\n"

    posts.each do |post|
      if post[:year] == year
        blog_content << "- [#{post[:title]}](#{post[:slug]})\n"
      end
    end
    blog_content << "{:.posts}\n\n"
    blog_content << "---\n\n\n" unless year == post_years.reverse.last
  end

  File.write("content/index.md", blog_content)
end

def build_pages(content_dir)
  head = File.read("partials/_head.html")
  header = File.read("partials/_header.html")
  footer = File.read("partials/_footer.html")

  Dir.glob("#{content_dir}/**/*.html").each do |file|
    file_content = File.read(file)
    file_destination_path = file.gsub(content_dir, "site")
    FileUtils.mkdir_p(File.dirname(file_destination_path))

    page_content = <<~PAGE
      <!DOCTYPE html>
      <html lang="en">
        #{head}
        <body>
        #{header}
        <main>
        #{file_content}
        </main>
        #{footer}
        </body>
      </html>
    PAGE

    File.open(file_destination_path, "wb") do |destination_file|
      destination_file.write(page_content)
    end
  end
end

def clean_html_files
  Dir.glob("site/*.html").each do |file_path|
    File.write(file_path, HtmlBeautifier.beautify(File.read(file_path)))
  end
end


def build_site
  start_time = Time.now
  # build_index_page
  build_pages("content/")
  build_pages("content/posts")
  clean_html_files
  # remove_html_extensions 
  # uncomment above once server is set up to handle all files as text/html
  end_time = Time.now 
  puts "Build complete | #{((end_time-start_time).to_f * 1000).round(2)} ms."
end

build_site