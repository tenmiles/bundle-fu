require File.expand_path('test_helper', File.join(File.dirname(__FILE__), '..'))

class JSBundleTest < Test::Unit::TestCase
  
  def test__bundle_js_files__bypass_bundle__should_bypass
    dummy_view.send :bundle_js_files, []
  end
  
  def test__bundle_js_files__should_include_contents
    bundled_js = dummy_view.send :bundle_js_files, ["/javascripts/js_1.js"]
    puts bundled_js
    assert_match("function js_1", bundled_js)
  end

  private

    def dummy_view
      @dummy_view = ActionView::Base.new
    end

end
