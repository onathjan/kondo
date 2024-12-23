module SiteBuilder
  
  require 'htmlbeautifier'
  require 'yaml'
  require_relative 'content_processor'
  require_relative 'template_renderer'

  def self.build_index_page
    file_content = File.read("content/index.md")
  
    file_content.sub!(/^(---\s*\n.*?\n---)[\s\S]*/m, '\1')
  
    File.open("content/index.md", 'w') do |file|
      file.puts file_content
      file.puts ""
    end
  
    posts = []
  
    Dir.glob("content/posts/*md").each do |file|
      front_matter, _ = ContentProcessor.read_front_matter(file)
      next if front_matter['draft'] == true
      title = front_matter['title']
      date = front_matter['date'].to_s
      slug = front_matter['slug'] + ".html" 
      posts << { date: date, title: title, slug: slug }
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
  
  def self.build_pages
    config_file = YAML.load_file("config/config.yaml")

    Dir.glob("content/**/*.md").each do |file|
      front_matter, body = ContentProcessor.read_front_matter(file)
      html_content = ContentProcessor.process_markdown(body)
  
      next if front_matter['draft']
  
      assigns = {
        'site_name' => config_file['site_name'],
        'title' => front_matter['title'],
        'date' => front_matter['date'],
        'content' => html_content
      }
  
      rendered_content = TemplateRenderer.render_template("templates/layout.liquid", assigns)
      output_file = "site/#{front_matter['slug']}.html"
      File.write(output_file, HtmlBeautifier.beautify(rendered_content))
    end
  end
end