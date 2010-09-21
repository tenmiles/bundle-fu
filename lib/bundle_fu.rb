class BundleFu

  @@content_store = {}
  def self.content_store
    @@content_store
  end

  @@default_options = {
    :name => "bundle",
    :compress => true,
    :css_path => "/stylesheets/cache",
    :js_path => "/javascripts/cache"
  }
  def self.default_options
    @@default_options
  end

  @@raise_read_errors = false
  def self.raise_read_errors
    @@raise_read_errors
  end

  def self.bundle_files(filenames)
    buffer = ""
    filenames.each do |filename|
      buffer << "/* --------- #{filename} --------- */\n"
      begin
        content = File.read(File.join(RAILS_ROOT, "public", filename))
      rescue
        if raise_read_errors
          raise
        else
          buffer << "/* FILE READ ERROR! */"
          next
        end
      end
      buffer << (yield(filename, content) || "")
    end
    buffer
  end
  
  module InstanceMethods
    # valid options:
    #   :name - The name of the css and js files you wish to output
    # returns true if a re-generation occurred.  False if not.
    def bundle(options={}, &block)
      # allow bypassing via the query string
      session[:bundle_fu] = (params[:bundle_fu].to_s == "true") if params.has_key?(:bundle_fu)

      options = BundleFu.default_options.merge(options)
      options[:bundle_fu] = session[:bundle_fu].nil? ? true : session[:bundle_fu]
      
      # allow them to bypass via parameter
      if bypass = options[:bypass]
        options[:bundle_fu] =
          if bypass.is_a?(Proc)
            ! bypass.call
          elsif bypass.is_a?(Symbol)
            ! send(bypass)
          else
            ! bypass
          end
      end
      
      paths = { :css => options[:css_path], :js => options[:js_path] }
      
      content = capture(&block)
      #content_changed = false
      
      new_files = nil
      abs_filelist_paths = [:css, :js].inject({}) do | hash, filetype |
        filename = "#{options[:name]}.#{filetype}.filelist"
        hash[filetype] = File.join(RAILS_ROOT, "public", paths[filetype], filename)
        hash
      end
      
      # only rescan file list if content_changed, or if a filelist cache file is missing
      unless content == BundleFu.content_store[options[:name]] && File.exists?(abs_filelist_paths[:css]) && File.exists?(abs_filelist_paths[:js])
        BundleFu.content_store[options[:name]] = content 
        new_files = {:js => [], :css => []}
        
        content.scan(/(href|src) *= *["']([^"^'^\?]+)/i).each do |property, value|
          case property
          when "src"
            new_files[:js] << value
          when "href"
            new_files[:css] << value
          end
        end
      end

      rails_version_less_2_2_0 = ( Rails.version < "2.2.0" )

      [:css, :js].each do |filetype|
        output_filename = File.join(paths[filetype], "#{options[:name]}.#{filetype}")
        abs_path = File.join(RAILS_ROOT, "public", output_filename)
        abs_filelist_path = abs_filelist_paths[filetype]
       
        filelist = FileList.open( abs_filelist_path )
        
        # check against newly parsed filelist.  If we didn't parse the filelist from the output, then check against the updated mtimes.
        new_filelist = new_files ? BundleFu::FileList.new(new_files[filetype]) : filelist.clone.update_mtimes
        
        unless new_filelist == filelist
          FileUtils.mkdir_p(File.join(RAILS_ROOT, "public", paths[filetype]))
          # regenerate everything
          if new_filelist.filenames.empty?
            # delete the javascript/css bundle file if it's empty, but keep the filelist cache
            FileUtils.rm_f(abs_path)
          else
            # call bundle_css_files or bundle_js_files to bundle all files listed.  output it's contents to a file
            output = self.send("bundle_#{filetype}_files", new_filelist.filenames, options)
            File.open( abs_path, "w") {|f| f.puts output } if output
          end
          new_filelist.save_as(abs_filelist_path)
        end
        
        if File.exists?(abs_path) && options[:bundle_fu]
          tag = filetype==:css ? stylesheet_link_tag(output_filename) : javascript_include_tag(output_filename)
          #concat doesn't need block.binding in Rails >= 2.2.0
          rails_version_less_2_2_0 ? concat( tag , block.binding) : concat( tag )
        end
      end
      
      unless options[:bundle_fu]
        #concat doesn't need block.binding in Rails >= 2.2.0
        rails_version_less_2_2_0 ? concat( content, block.binding ) : concat( content )
      end
    end

    private

    def bundle_js_files(filenames, options = {})
      packr = Object.const_defined?("Packr")
      output =
        BundleFu.bundle_files(filenames) do |filename, content|
          if options[:compress]
            packr ? content : JSMinimizer.minimize_content(content)
          else
            content
          end
        end

      if packr # use Packr plugin (http://blog.jcoglan.com/packr/)
        Packr.new.pack(output, options[:packr_options] || {:shrink_vars => false, :base62 => false})
      else
        output
      end

    end

    def bundle_css_files(filenames, options = {})
      BundleFu.bundle_files(filenames) do |filename, content|
        BundleFu::CSSUrlRewriter.rewrite_urls(filename, content, self)
      end
    end

  end
end
