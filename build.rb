require 'fileutils'
require 'htmlbeautifier'
require 'kramdown'
require 'yaml'

config_file = YAML.safe_load(File.read('config.yml'))
SITE_NAME = config_file["site_name"]
SITE_URL = config_file["site_url"]

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

def parse_markdown(markdown)
  markdown = markdown.gsub(/^### (.*?)$/, "<h3>\\1</h3>")
                     .gsub(/^## (.*?)$/, "<h2>\\1</h2>")
                     .gsub(/^# (.*?)$/, "<h1>\\1</h1>")
                     .gsub(/\*\*(.*?)\*\*/i, "<strong>\\1</strong>")
                     .gsub(/__(.*?)__/i, "<strong>\\1</strong>")
                     .gsub(/\*(.*?)\*/i, "<em>\\1</em>")
                     .gsub(/_(.*?)_/i, "<em>\\1</em>")
                     .gsub(/^(\*|\-|\+)\s+(.*)$/, "<ul><li>\\2</li></ul>") 
                     .gsub(/^(\d+)\.\s+(.*)$/, "<ol><li>\\2</li></ol>") 
                     .gsub(/`(.*?)`/, "<code>\\1</code>")
                     .gsub(/```(.*?)```/m, "<pre><code>\\1</code></pre>")

  # Wrap regular paragraphs in <p> tags, but not if it's a list, code block, or header
  markdown = markdown.split("\n\n").map do |block|
    if block =~ /^(#|<h\d|ul|ol|code|pre|strong|em)/  # if block already has HTML tags, don't wrap in <p>
      block
    else
      "<p>#{block.strip}</p>"  # wrap regular paragraphs in <p>
    end
  end.join("\n\n")

  markdown
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

def build_pages(content_dir)
  header = File.read("partials/_header.html")
  footer = File.read("partials/_footer.html")

  Dir.glob("#{content_dir}/*.html").each do |file|
    front_matter, body = read_front_matter(file)
    file_destination_path = "site/#{front_matter["slug"]}.html"
    FileUtils.mkdir_p(File.dirname(file_destination_path))

    next if content_dir == "content/posts" && front_matter['draft']

    page_content = <<~PAGE
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>#{front_matter["title"]} | #{SITE_NAME}</title>

          <!-- Favicon for older and all browsers -->
          <link rel="icon" href="favicon.ico" type="image/x-icon">

          <!-- Modern .png favicon for better resolution -->
          <link rel="icon" href="favicon.png" type="image/png" sizes="32x32">

          <!-- Scalable .svg for future-proofing -->
          <link rel="icon" href="favicon.svg" type="image/svg+xml">

          <link rel="stylesheet" type="text/css" href="assets/css/styles.css" />

          <!-- Primary Meta Tags -->
          <meta name="title" content="#{front_matter["title"]}">
          <meta name="description" content="#{front_matter["description"]}">

          <!-- Open Graph -->
          <meta property="og:site-name" content="#{SITE_NAME}">
          <meta property="og:title" content="#{front_matter["title"]}">
          <meta property="og:type" content="article">
          <meta property="og:url" content="#{SITE_URL}/#{front_matter["slug"]}">
          <meta property="og:description" content="#{front_matter["description"]}">
          <meta property="og:image" content="#{SITE_URL}/assets/images/open-graph-image.jpg">
          <meta property="og:image:width" content="1200" />
          <meta property="og:image:height" content="675" />

          <!-- Twitter Card -->
          <meta name="twitter:card" content="summary_large_image">
          <meta property="twitter:url" content="#{SITE_URL}/#{front_matter["slug"]}">
          <meta name="twitter:title" content="#{front_matter["title"]}">
          <meta name="twitter:description" content="#{front_matter["description"]}">
          <meta name="twitter:image" content="#{SITE_URL}/assets/images/open-graph-image.jpg">
          <meta name="twitter:image:width" content="1200" />
          <meta name="twitter:image:height" content="675" />
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
  build_pages("content")
  build_pages("content/posts")
  clean_html_files
end

puts parse_markdown(File.read("README.md"))