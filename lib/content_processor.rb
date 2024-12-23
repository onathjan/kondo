module ContentProcessor
  require 'kramdown'
  
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
end