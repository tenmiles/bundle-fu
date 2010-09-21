class BundleFu::CSSUrlRewriter
  class << self

    # rewrite the URL reference paths
    # url(../../../images/active_scaffold/default/add.gif);
    # url(/stylesheets/active_scaffold/default/../../../images/active_scaffold/default/add.gif);
    # url(/stylesheets/active_scaffold/../../images/active_scaffold/default/add.gif);
    # url(/stylesheets/../images/active_scaffold/default/add.gif);
    # url('/images/active_scaffold/default/add.gif');
    def rewrite_urls(filename, content, asset_tag_helper)
      content.gsub!(/url *\(([^\)]+)\)/i) do
        inner = $1; match = $&
        data_ = (inner[0,1] == '"' || inner[0,1] == "'") ? inner[1,5] : inner[0,5]
        if data_ == 'data:'
          match
        else
          path = rewrite_relative_path(filename, inner)
          if path.start_with?('/images')
            "url(#{asset_tag_helper.image_path(path)})"
          elsif ! path.include?("://")
            image_dir = File.dirname(path)
            image_dir = image_dir[1..-1] if image_dir[0,1] == '/'
            image_path = asset_tag_helper.send(:compute_public_path, File.basename(path), image_dir)
            "url(#{image_path})"
          else
            "url(#{path})"
          end
        end
      end
      content
    end

    # rewrites a relative path to an absolute path, removing excess "../" and "./"
    # rewrite_relative_path("stylesheets/default/global.css", "../image.gif") => "/stylesheets/image.gif"
    def rewrite_relative_path(source_filename, relative_url)
      relative_url = relative_url.to_s.strip
      relative_url.gsub!(/["']/, "")

      del = '/'
      return relative_url if relative_url.include?("://")

      url_path = relative_url
      if relative_url[0,1] != del

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

  end
end
