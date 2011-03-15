require File.expand_path('test_helper', File.join(File.dirname(__FILE__), '..'))

class CSSBundleTest < Test::Unit::TestCase

#  def setup
#    ENV["RAILS_ASSET_ID"] = '1234567890'
#  end
#
#  def teardown
#    ENV.delete("RAILS_ASSET_ID")
#  end

  def test__rewrite_relative_path__should_rewrite
    assert_rewrites("/stylesheets/active_scaffold/default/stylesheet.css", 
      "../../../images/spinner.gif" => "/images/spinner.gif",
      "../../../images/./../images/goober/../spinner.gif" => "/images/spinner.gif"
    )
    
    assert_rewrites("stylesheets/active_scaffold/default/./stylesheet.css", 
      "../../../images/spinner.gif" => "/images/spinner.gif")
      
    assert_rewrites("stylesheets/main.css", 
      "image.gif" => "/stylesheets/image.gif")
      
    assert_rewrites("/stylesheets////default/main.css", 
      "..//image.gif" => "/stylesheets/image.gif")
      
    assert_rewrites("/stylesheets/default/main.css", 
      "/images/image.gif" => "/images/image.gif")

    assert_rewrites("/stylesheets/some/theme.css",
      "images/image.gif" => "/stylesheets/some/images/image.gif")
  end
  
  def test__rewrite_relative_path__should_strip_spaces_and_quotes
    assert_rewrites("stylesheets/main.css", 
      "'image.gif'" => "/stylesheets/image.gif",
      " image.gif " => "/stylesheets/image.gif"
    )
  end
  
  def test__rewrite_relative_path__shouldnt_rewrite_if_absolute_url
    assert_rewrites("stylesheets/main.css", 
      " 'http://www.url.com/images/image.gif' " => "http://www.url.com/images/image.gif",
      "http://www.url.com/images/image.gif" => "http://www.url.com/images/image.gif",
      "ftp://www.url.com/images/image.gif" => "ftp://www.url.com/images/image.gif"
    )
  end
  
  def test__bundle_css_file__should_rewrite_relative_path
    bundled_css = dummy_view.send :bundle_css_files, ["/stylesheets/css_3.css"]
    assert_match("background-image: url(/images/background.gif)", bundled_css)
    assert_match("background-image: url(/images/groovy/background_2.gif)", bundled_css)
  end
  
  def test__bundle_css_files__no_images__should_return_content
    bundled_css = dummy_view.send :bundle_css_files, ["/stylesheets/css_1.css"]
    assert_match("css_1 { }", bundled_css)
  end

  def test__bundle_css_file__should_not_rewrite_data_urls
    bundled_css = dummy_view.send :bundle_css_files, ["/stylesheets/css_4.css"]
    
    pattern = 
      Regexp.escape("body {background: URL(data:image/jpg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/") +
        '.*?' +
      Regexp.escape(") left bottom repeat-x !important;")
    assert_match /#{pattern}/mx, bundled_css # # multiline, ignore whitespace

    pattern =
      Regexp.escape("ul > li {") +
        '.*?' +
      Regexp.escape("margin:0 0 .1em;") +
        '.*?' +
      Regexp.escape("background:url(data:image/gif;base64,R0lGODlhEAAOALMAAOazToeHh0tLS/7LZv/0")
        '.*?' +
      Regexp.escape(")top left no-repeat;")
    assert_match /#{pattern}/mx, bundled_css # # multiline, ignore whitespace

    pattern =
      Regexp.escape(".box") +
        '.*?' +
      Regexp.escape("{") +
        '.*?' +
      Regexp.escape("width: 100px;")
        '.*?' +
      Regexp.escape("height: 100px;")
        '.*?' +
      Regexp.escape("background-image: url(\"data:image/gif;base64,R0lGODlhAwADAIAAAP///8zMzCH5BAAAAAAALAAAAAADAAMAAAIEBHIJBQA7\");")
        '.*?' +
      Regexp.escape("border: 1px solid gray;")
    assert_match /#{pattern}/mx, bundled_css # # multiline, ignore whitespace
  end

  def test__bundle_css_file__adds_rails_asset_ids_for_existing_image_urls
    bundled_css = dummy_view.send :bundle_css_files, ["/stylesheets/css_5.css"]
    #puts bundled_css
    pattern = Regexp.escape("background-image: url(/images/test1.gif?") + "\\d+" + Regexp.escape(')')
    assert_match(Regexp.new(pattern), bundled_css)

    pattern = Regexp.escape("background-image: url(/images/test2.png?") + "\\d+" + Regexp.escape(')')
    assert_match(Regexp.new(pattern), bundled_css)

    #pattern = Regexp.escape("background: url(/stylesheets/images/test3.jpg) no-repeat scroll;")
    #assert_match(Regexp.new(pattern), bundled_css)

    pattern = Regexp.escape("background: url(/stylesheets/images/test3.jpg?") + "\\d+" + Regexp.escape(') no-repeat scroll;')
    assert_match(Regexp.new(pattern), bundled_css)

    assert_match("background-image: url(/images/non_existing.jpg)", bundled_css)
  end

  private
  
    def assert_rewrites(source_filename, rewrite_map)
      rewrite_map.each_pair do |source, dest|
        assert_equal(dest, BundleFu::CSSUrlRewriter.rewrite_relative_path(source_filename, source))
      end
    end

    def dummy_view
      @dummy_view = ActionView::Base.new
      if @dummy_view.respond_to? :config
        # rails 3.0.0+
        def @dummy_view.config
          config = {}

          def config.asset_path
            nil
          end
          config['asset_path'] = config.asset_path

          def config.asset_host
            nil
          end
          config['asset_host'] = config.asset_host

          def config.assets_dir
            File.join(Rails.root.to_s, 'public')
          end
          config['assets_dir'] = config.assets_dir

          config
        end
      end
      @dummy_view
    end

end
