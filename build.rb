require 'fileutils'
require 'htmlbeautifier'
require 'kramdown'
require 'yaml'

config_file = YAML.load_file("config.yml")
SITE_NAME = config_file["site-name"]

def read_front_matter(file_path)
  content = File.read(file_path)

  if content =~ /\A---\n(.*?)\n---\n/m
    front_matter = YAML.safe_load($1)
    body = $'
    [front_matter, body]
  else
    [nil, body]
  end
end

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

def build_main_pages
  # head = File.read("partials/_head.html")
  header = File.read("partials/_header.html")
  footer = File.read("partials/_footer.html")

  Dir.glob("content/*.html").each do |file|
    next if file == "content/index.html"
    front_matter, body = read_front_matter(file)
    file_destination_path = file.gsub("content", "site")
    FileUtils.mkdir_p(File.dirname(file_destination_path))

    page_content = <<~PAGE
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <link rel="icon" type="image/png" sizes="64x64" href="assets/images/favicon.png">
          <link rel="apple-touch-icon" href="assets/images/favicon.png">
          <link rel="stylesheet" type="text/css" href="assets/css/styles.css" />
          <title>#{front_matter["title"]} | Kondo</title>
        </head>
        <body>
        #{header}
        <main>
        #{body}
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
  # build_index_page
  build_main_pages
  # build_pages("content/posts")
  clean_html_files
end