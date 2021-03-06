class MockView < ActionView::Base
  
  #include BundleFu::InstanceMethods
  
  # set Rails.root.to_s to fixtures dir so we use those files
  #::Rails.root.to_s = File.join(File.dirname(__FILE__), 'fixtures')
  
  attr_accessor :output
  attr_accessor :session
  attr_accessor :params
  
  def initialize
    super
    @output = ""
    @session = {}
    @params = {}
  end
  
  def capture
    yield
  end
  
  def concat(output, *args)
    @output << output
  end
  
  def stylesheet_link_tag(*args)
    args.collect{|arg| "<link href=\"#{arg}?#{File.mtime(File.join(Rails.root, 'public', arg)).to_i}\" media=\"screen\" rel=\"Stylesheet\" type=\"text/css\" />" } * "\n"
  end
  
  def javascript_include_tag(*args)
    args.collect{|arg| "<script src=\"#{arg}?#{File.mtime(File.join(Rails.root, 'public', arg)).to_i}\" type=\"text/javascript\"></script>" } * "\n"
  end

  # mock-out override :
  def rails_asset_id(source)
    path = File.join(Rails.root, 'public', source)
    File.exist?(path) ? File.mtime(path).to_i.to_s : ''
  end

end