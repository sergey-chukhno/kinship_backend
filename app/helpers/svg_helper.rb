module SvgHelper
  def show_svg(path, options = {})
    file = File.read(Rails.root.join("app", "assets", "images", "icons", path.to_s))
    doc = Nokogiri::HTML::DocumentFragment.parse file
    svg = doc.at_css "svg"

    options.each { |attr, value| svg[attr.to_s] = value }

    doc.to_html.html_safe
  end
end
