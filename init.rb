# load all files
["bundle_fu", "bundle_fu/js_minimizer", "bundle_fu/css_url_rewriter", "bundle_fu/file_list"].each do |file|
  require file
end

ActionView::Base.send :include, BundleFu::InstanceMethods