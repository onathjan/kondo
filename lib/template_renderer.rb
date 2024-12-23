module TemplateRenderer
  require 'liquid'

  def self.render_template(template_file, assigns)
    template = File.read(template_file)
    Liquid::Template.parse(template).render(assigns)
  end
end