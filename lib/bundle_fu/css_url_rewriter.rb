class BundleFu::CSSUrlRewriter
  class << self
    include ActionView::Helpers::AssetTagHelper

    # rewrites a relative path to an absolute path, removing excess "../" and "./"
    # rewrite_relative_path("stylesheets/default/global.css", "../image.gif") => "/stylesheets/image.gif"
    def rewrite_relative_path(source_filename, relative_url)
      relative_url = relative_url.to_s.strip
      relative_url.gsub!(/["']/, "")

      del = '/'
      return relative_url if relative_url.include?("://")

      url_path = relative_url
      if relative_url.first != del

        elements = File.join(del, File.dirname(source_filename))
        elements.gsub!(/\/+/, del)
        elements = elements.split(del) + relative_url.gsub(/\/+/, del).split(del)

        index = 0
        while elements[index]
          if elements[index] == "."
            elements.delete_at(index)
          elsif elements[index] == ".."
            next if index==0
            index -= 1
            2.times { elements.delete_at(index) }
          else
            index += 1
          end
        end

        url_path = elements * del
      end

      url_path
    end  
  
    # rewrite the URL reference paths
    # url(../../../images/active_scaffold/default/add.gif);
    # url(/stylesheets/active_scaffold/default/../../../images/active_scaffold/default/add.gif);
    # url(/stylesheets/active_scaffold/../../images/active_scaffold/default/add.gif);
    # url(/stylesheets/../images/active_scaffold/default/add.gif);
    # url('/images/active_scaffold/default/add.gif');
    def rewrite_urls(filename, content)
      content.gsub!(/url *\(([^\)]+)\)/i) do
        inner = $1; match = $&
        if inner.start_with?('data:') ||
            ( (inner.at(0) == '"' || inner.at(0) == "'") && inner[1..-1].start_with?('data:') )
          match
        else
          path = rewrite_relative_path(filename, inner)
          case path
          when /^\/images\/(.*)/
            "url(#{image_path($1)})"
          else
            path
          end
        end
      end
      content
    end
    
  end
end
