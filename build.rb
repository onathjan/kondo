require 'fileutils'
require 'yaml'

SITE_NAME = "Kondo"
SITE_URL = "https://www.gokondo.io"

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
  lines = markdown.split("\n")
  html = []
  inside_ul = false
  inside_ol = false

  lines.each do |line|
    line.strip!

    # Handle unordered list items
    if line.match(/^(\*|\-|\+)\s+(.*)$/)
      unless inside_ul
        html << "<ul>"
        inside_ul = true
      end
      html << "  <li>#{$2}</li>"
      next
    elsif inside_ul
      html << "</ul>"
      inside_ul = false
    end

    # Handle ordered list items
    if line.match(/^\d+\.\s+(.*)$/)
      unless inside_ol
        html << "<ol>"
        inside_ol = true
      end
      html << "  <li>#{$1}</li>"
      next
    elsif inside_ol
      html << "</ol>"
      inside_ol = false
    end

    # Handle headers
    if line.match(/^###### (.*?)$/)
      html << "<h6>#{$1}</h6>"
      next
    elsif line.match(/^##### (.*?)$/)
      html << "<h5>#{$1}</h5>"
      next
    elsif line.match(/^#### (.*?)$/)
      html << "<h4>#{$1}</h4>"
      next
    elsif line.match(/^### (.*?)$/)
      html << "<h3>#{$1}</h3>"
      next
    elsif line.match(/^## (.*?)$/)
      html << "<h2>#{$1}</h2>"
      next
    elsif line.match(/^# (.*?)$/)
      html << "<h1>#{$1}</h1>"
      next
    end

    # Paragraphs (fallback for any non-matching lines)
    html << "<p>#{line}</p>" unless line.empty?
  end

  # Close any remaining open tags
  html << "</ul>" if inside_ul
  html << "</ol>" if inside_ol

  # Join lines back together and add inline styling
  html.join("\n")
      .gsub(/\*\*(.*?)\*\*/, '<strong>\1</strong>') 
      .gsub(/\*(.*?)\*/i, '<em>\1</em>')
      .gsub(/\[([^\]]+)\]\(([^\)]+)\)/, '<a href="\2">\1</a>')
      .gsub(/`([^`]+)`/, '<code>\1</code>')
      .gsub(/---/, "<hr>")
end

def beautify_html(input)
  indent_level = 0
  indent_tags = ['body', 'header', 'nav', 'ul', 'ol', 'div', 'main', 'footer']
  output = []

  input.strip.split("\n").each do |line|
    line.strip!
    next if line.empty?

    # Check if it's a closing tag for decreasing indent
    if closing_tag?(line, indent_tags)
      indent_level -= 1 if indent_level > 0
      output << "#{"  " * indent_level}#{line}"
    # Check if it's an opening tag for indenting
    elsif opening_tag?(line, indent_tags)
      output << "#{"  " * indent_level}#{line}"
      indent_level += 1
    else
      output << "#{"  " * indent_level}#{line}"
    end
  end

  output.join("\n")
end

def opening_tag?(line, indent_tags)
  tag_name = extract_tag_name(line)
  tag_name && indent_tags.include?(tag_name)
end

def closing_tag?(line, indent_tags)
  tag_name = extract_tag_name(line)
  tag_name && indent_tags.include?(tag_name) && line.start_with?("</")
end

def extract_tag_name(line)
  # Matches both opening and closing tag names (e.g., <body> or </body>)
  match = line.match(/<\/?([a-zA-Z0-9-]+)/)
  match ? match[1] : nil
end

def build_index_page
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

    if ["index", "about", "now", "projects"].include?(front_matter["slug"]) 
      page_type = "website" 
    else 
      page_type = "article"
    end

    front_matter["title"]

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

          <!-- Primary Meta Tags -->
          <meta name="generator" content="Kondo—a minimalist SSG">
          <meta name="title" content="#{front_matter["title"]}">
          <meta name="description" content="#{front_matter["description"]}">

          <!-- Open Graph -->
          <meta property="og:site-name" content="#{SITE_NAME}">
          <meta property="og:title" content="#{front_matter["title"]}">
          <meta property="og:type" content="#{page_type}">
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

def generate_sitemap
  urls = Dir.glob("content/**/*.md").map do |file|
    front_matter, _ = read_front_matter(file)
    next if front_matter["draft"]
    slug = front_matter["slug"]
    updated_on = front_matter["updated_on"]
    loc = "https://www.gokondo.io/#{slug}".sub("index", '').chomp('/')
    [loc, updated_on]
  end.compact

  sitemap_body = urls.map do |loc, lastmod|
    <<~XML
      <url>
        <loc>#{loc}</loc>
        <lastmod>#{lastmod}</lastmod>
      </url>
    XML
  end.join.strip

  sitemap = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{sitemap_body}
    </urlset>
  XML

  File.write("site/sitemap.xml", sitemap)
end

def build_site
  build_index_page
  build_pages
  generate_sitemap
end