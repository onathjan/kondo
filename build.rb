require 'fileutils'
require 'yaml'
require 'cgi'
require 'time'

SITE_NAME = "Kondo"
SITE_URL = "https://www.gokondo.io"
YOUR_NAME = "Marie Kondo"

def build_index_page
  file_content = File.read("content/index.md")

  file_content.sub!(/^(---\s*\n.*?\n---)[\s\S]*/m, '\1')

  File.open("content/index.md", 'w') do |file|
    file.puts file_content
    file.puts ""
  end

  posts = []

  Dir.glob("content/posts/*md").each do |file|
    front_matter, _ = read_front_matter(file)
    next if front_matter['draft'] == true
    title = front_matter['title']
    date = front_matter['date'].to_s
    year = front_matter['date'].to_s[0..4]
    slug = front_matter['slug'] + ".html" 
    posts << { year: year, date: date, title: title, slug: slug }
  end

  posts.sort_by! { |post| post[:date] }.reverse!

  posts_content = posts.map do |post|
    <<~POST_LINK
      ###### #{post[:date]}
      ## [#{post[:title]}](#{post[:slug]})
    POST_LINK
  end.join("\n")

  open("content/index.md", 'a') { |f|
    f.puts posts_content
  }
end

def build_pages
  header, footer = %w[_header _footer].map { |f| File.read("partials/#{f}.html") }

  Dir.glob("content/**/*.md").each do |file|
    front_matter, body = read_front_matter(file)
    body = parse_markdown(body)
    file_destination_path = "site/#{front_matter["slug"]}.html"
    FileUtils.mkdir_p(File.dirname(file_destination_path))

    next if front_matter['draft'] == true

    front_matter["title"] # is this even needed?

    page_content = <<~PAGE
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>#{front_matter["title"]} | #{SITE_NAME}</title>

          <link rel="icon" href="favicon.png" type="image/png">
          <link rel="icon" href="favicon.ico" type="image/x-icon">
          <link rel="apple-touch-icon" href="assets/images/favicon.png">

          <link rel="stylesheet" type="text/css" href="assets/css/styles.css" />

          <link rel="alternate" type="application/rss+xml" href="/rss.xml" title="RSS Feed">

          <!-- Primary Meta Tags -->
          <meta name="generator" content="Kondo—a minimalist SSG">
          <meta name="title" content="#{front_matter["title"]}">
          <meta name="description" content="#{front_matter["description"]}">

          <!-- Open Graph -->
          <meta property="og:site-name" content="#{SITE_NAME}">
          <meta property="og:title" content="#{front_matter["title"]}">
          <meta property="og:type" content="#{front_matter["page_type"]}">
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

    page_content = beautify_html(page_content)

    File.open(file_destination_path, "wb") do |destination_file|
      destination_file.write(page_content)
    end
  end
end

def build_site
  build_index_page
  build_pages
  generate_sitemap
  generate_rss_feed
end
