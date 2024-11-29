require 'fileutils'
require 'htmlbeautifier'
require 'kramdown'
require 'yaml'

SITE_NAME = "Kondo"

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

  Dir.glob("content/posts/*html").each do |file|
    front_matter, _ = read_front_matter(file)
    year = file[14..17]
    date = file[14..23]
    title = front_matter['title']
    slug = front_matter['slug'] + ".html" 
    draft = front_matter['draft']
    posts << { year: year, date: date, title: title, slug: slug } unless draft
  end

  posts.sort_by! { |post| post[:date] }.reverse!

  blog_content = <<~BLOG
    ---
    title: Home
    slug: index
    ---

    <ol class="posts">
  BLOG
  posts.each do |post|
    blog_content << "<li><a href='#{post[:slug]}'>#{post[:title]}</a></li>"
  end

  blog_content << "</ol>"

  File.write("content/index.html", blog_content)
end

def build_main_pages
  # head = File.read("partials/_head.html")
  header = File.read("partials/_header.html")
  footer = File.read("partials/_footer.html")

  Dir.glob("content/*.html").each do |file|
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
          <title>#{front_matter["title"]} | #{SITE_NAME}</title>
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

    page_content.gsub!("Home | #{SITE_NAME}", "#{SITE_NAME}") if front_matter["title"] == "Home"

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
  build_index_page
  build_main_pages
  # build_pages("content/posts")
  clean_html_files
end