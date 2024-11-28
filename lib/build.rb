require 'fileutils'
require 'htmlbeautifier'
require 'kramdown'
require 'liquid'
require 'yaml'

config_file = YAML.load_file("config.yml")
SITE_NAME = config_file["site-name"]

def read_front_matter(file_path)
  content = File.read(file_path)
  if content =~ /\A---\n(.*?)\n---\n/m
    front_matter = YAML.load($1)
    body = $'
    [front_matter, body]
  else
    [nil, content]
  end
end

def process_markdown(content)
  Kramdown::Document.new(content, {auto_ids: false}).to_html
end

def render_template(template_file, assigns)
  template = File.read(template_file)
  Liquid::Template.parse(template).render(assigns)
end

def copy_assets
  FileUtils.cp_r('assets', 'site')
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

def build_pages(content_dir)
  Dir.glob("#{content_dir}/*.md").each do |file|
    front_matter, body = read_front_matter(file)
    html_content = process_markdown(body)

    next if content_dir == "content/posts" && front_matter['draft']

    assigns = {
      'title' => front_matter['title'],
      'date' => front_matter['date'],
      'content' => html_content
    }

    rendered_content = render_template("templates/main_layout.liquid", assigns)
    output_file = "site/#{front_matter['slug']}.html"
    File.write(output_file, rendered_content)
  end
end

def clean_html_files
  Dir.glob("site/*.html").each do |file_path|
    File.write(file_path, HtmlBeautifier.beautify(File.read(file_path)))
  end
end

def remove_html_extensions
  Dir.glob("site/*html").each do |file|
    File.rename(file, file.delete_suffix(".html"))
  end
end

def build_site
  start_time = Time.now
  build_index_page
  build_pages("content/")
  build_pages("content/posts")
  clean_html_files
  # remove_html_extensions 
  # uncomment above once server is set up to handle all files as text/html
  end_time = Time.now 
  puts "Build complete | #{((end_time-start_time).to_f * 1000).round(2)} ms."
end

build_site