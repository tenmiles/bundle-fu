# emulates a minimal Rails environment for tests

# enable testing with different version of rails via argv :
# ruby request_exception_handler_test.rb RAILS_VERSION=2.3.5

version =
  if ARGV.find { |opt| /RAILS_VERSION=([\d\.]+)/ =~ opt }
    $~[1]
  else
    # rake test RAILS_VERSION=2.3.8
    ENV['RAILS_VERSION']
  end

if version
  gem 'activesupport', "= #{version}"
  gem 'activerecord', "= #{version}"
  gem 'actionpack', "= #{version}"
  gem 'actionmailer', "= #{version}"
  gem 'rails', "= #{version}"
else
  gem 'activesupport'
  gem 'activerecord'
  gem 'actionpack'
  gem 'actionmailer'
  gem 'rails'
end

require 'rails/version'
puts "emulating Rails.version = #{Rails::VERSION::STRING}"

require 'active_support'
require 'active_support/core_ext/kernel/reporting'
# Make double-sure the RAILS_ENV is set to test :
silence_warnings { RAILS_ENV = "test" }
silence_warnings { RAILS_ROOT = File.join(File.dirname(__FILE__), 'fixtures') }

module Rails
  class << self

    def initialized?
      @initialized || false
    end

    def initialized=(initialized)
      @initialized ||= initialized
    end

    def logger
      if defined?(RAILS_DEFAULT_LOGGER)
        RAILS_DEFAULT_LOGGER
      else
        Logger.new($stdout)
      end
    end

    def backtrace_cleaner
      @@backtrace_cleaner ||= begin
        require 'rails/gem_dependency' # backtrace_cleaner depends on this !
        require 'rails/backtrace_cleaner'
        Rails::BacktraceCleaner.new
      end
    end

    def root
      Pathname.new(RAILS_ROOT) if defined?(RAILS_ROOT)
    end

    def env
      @_env ||= ActiveSupport::StringInquirer.new(RAILS_ENV)
    end

    def version
      VERSION::STRING
    end

    def public_path
      @@public_path ||= self.root ? File.join(self.root, "public") : "public"
    end

    def public_path=(path)
      @@public_path = path
    end
  end
end

require 'action_controller'
require 'action_view'
require 'action_view/base'

if Rails.version >= '3.0.0'
  
end

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../lib')
