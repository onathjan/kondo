require 'fileutils'
require 'yaml'
require 'cgi'
require 'time'

SITE_NAME = "Kondo"
SITE_URL = "https://www.gokondo.io"
YOUR_NAME = "Marie Kondo"

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
  inside_code_block = false
  code_block_buffer = []

  lines.each do |line|
    line.strip!

    if line.match(/^```/)
      if inside_code_block
        html << "<pre><code>#{CGI.escapeHTML(code_block_buffer.join("\n"))}</code></pre>"
        code_block_buffer = []
        inside_code_block = false
      else
        inside_code_block = true
      end
      next
    end

    if inside_code_block
      min_indentation = code_block_buffer.reject(&:empty?).map { |line| line[/^\s*/].size }.min || 0
      normalized_code = code_block_buffer.map { |line| line.sub(/^\s{0,#{min_indentation}}/, '') }
    
      html << "<pre><code>#{CGI.escapeHTML(normalized_code.join("\n"))}</code></pre>"
      code_block_buffer = []
      inside_code_block = false
    end

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

    html << "<p>#{line}</p>" unless line.empty?
  end

  html << "</ul>" if inside_ul
  html << "</ol>" if inside_ol

  html.join("\n")
      .gsub(/\*\*(.*?)\*\*/, '<strong>\1</strong>') 
      .gsub(/\*(.*?)\*/i, '<em>\1</em>')
      .gsub(/\[([^\]]+)\]\(([^\)]+)\)/, '<a href="\2">\1</a>')
      .gsub(/`([^`]+)`/, '<code>\1</code>')
      .gsub(/^\s*[-*_]{3,}\s*$/, '<hr>')
end


def beautify_html(input)
  indent_level = 0
  indent_tags = ['html', 'head', 'body', 'header', 'nav', 'ul', 'ol', 'div', 'main', 'footer']
  output = []

  input.strip.split("\n").each do |line|
    line.strip!
    next if line.empty?

    if closing_tag?(line, indent_tags)
      indent_level -= 1 if indent_level > 0
      output << "#{"  " * indent_level}#{line}"
    elsif opening_tag?(line, indent_tags)
      output << "#{"  " * indent_level}#{line}"
      indent_level += 1
    else
      output << "#{"  " * indent_level}#{line}"
    end
  end

  output.join("\n")
end

def beautify_xml(input)
  indent_level = 0
  indent_tags = ['rss', 'channel', 'item']
  output = []

  input.strip.split("\n").each do |line|
    line.strip!
    next if line.empty?

    if closing_tag?(line, indent_tags)
      indent_level -= 1 if indent_level > 0
      output << "#{"  " * indent_level}#{line}"
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
  match = line.match(/<\/?([a-zA-Z0-9-]+)/)
  match ? match[1] : nil
end

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

def generate_rss_feed

  rss_content = <<~RSS
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0">
      <channel>
        <title>My Kondo Blog</title>
        <link>https://www.gokondo.io</link>
        <description>A minimalist blog</description>
        <lastBuildDate>#{Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")}</lastBuildDate>
  RSS

  Dir.glob("content/**/*.md").each do |file|
    front_matter, _ = read_front_matter(file)

    next if front_matter["page_type"] = "website"

    slug = front_matter["slug"]
    updated_on = Time.parse(front_matter["updated_on"]).strftime("%a, %d %b %Y %H:%M:%S %z")
    
    description = front_matter["description"].empty? ? "No description available." : front_matter["description"]
    
    rss_content += <<~RSS
      <item>
        <title>#{front_matter["title"]}</title>
        <link>https://www.gokondo.io/#{slug}</link>
        <description>#{description}</description>
        <pubDate>#{updated_on}</pubDate>
        <guid>https://www.gokondo.io/#{slug}</guid>
      </item>
    RSS
  end

  rss_content += <<~RSS
      </channel>
    </rss>
  RSS

  File.write("site/rss.xml", beautify_xml(rss_content))
end

def build_site
  build_index_page
  build_pages
  generate_sitemap
  generate_rss_feed
end