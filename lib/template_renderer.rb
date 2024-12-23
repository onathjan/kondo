module TemplateRenderer
  require 'liquid'

  def render_template(template_file, assigns)
    template = File.read(template_file)
    Liquid::Template.parse(template).render(assigns)
  end
end