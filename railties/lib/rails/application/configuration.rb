require 'rails/engine/configuration'

module Rails
  class Application
    class Configuration < ::Rails::Engine::Configuration
      include ::Rails::Configuration::Deprecated

      attr_accessor :allow_concurrency, :cache_classes, :cache_store,
                    :secret_token, :consider_all_requests_local, :dependency_loading,
                    :filter_parameters,  :log_level, :logger, :metals,
                    :plugins, :preload_frameworks, :reload_engines, :reload_plugins,
                    :serve_static_assets, :time_zone, :whiny_nils

      def initialize(*)
        super
        @allow_concurrency   = false
        @filter_parameters   = []
        @dependency_loading  = true
        @serve_static_assets = true
        @time_zone           = "UTC"
        @consider_all_requests_local = true
        @session_store = :cookie_store
        @session_options = {}
      end

      def middleware
        @middleware ||= default_middleware_stack
      end

      def metal_loader
        @metal_loader ||= Rails::Application::MetalLoader.new
      end

      def paths
        @paths ||= begin
          paths = super
          paths.app.controllers << builtin_controller if builtin_controller
          paths.config.database    "config/database.yml"
          paths.config.environment "config/environments", :glob => "#{Rails.env}.rb"
          paths.lib.templates      "lib/templates"
          paths.log                "log/#{Rails.env}.log"
          paths.tmp                "tmp"
          paths.tmp.cache          "tmp/cache"
          paths.vendor             "vendor", :load_path => true
          paths.vendor.plugins     "vendor/plugins"

          if File.exists?("#{root}/test/mocks/#{Rails.env}")
            ActiveSupport::Deprecation.warn "\"RAILS_ROOT/test/mocks/#{Rails.env}\" won't be added " <<
              "automatically to load paths anymore in future releases"
            paths.mocks_path  "test/mocks", :load_path => true, :glob => Rails.env
          end

          paths
        end
      end

      # Enable threaded mode. Allows concurrent requests to controller actions and
      # multiple database connections. Also disables automatic dependency loading
      # after boot, and disables reloading code on every request, as these are
      # fundamentally incompatible with thread safety.
      def threadsafe!
        self.preload_frameworks = true
        self.cache_classes = true
        self.dependency_loading = false
        self.allow_concurrency = true
        self
      end

      # Loads and returns the contents of the #database_configuration_file. The
      # contents of the file are processed via ERB before being sent through
      # YAML::load.
      def database_configuration
        require 'erb'
        YAML::load(ERB.new(IO.read(paths.config.database.to_a.first)).result)
      end

      def cache_store
        @cache_store ||= begin
          if File.exist?("#{root}/tmp/cache/")
            [ :file_store, "#{root}/tmp/cache/" ]
          else
            :memory_store
          end
        end
      end

      def builtin_controller
        File.expand_path('../info_routes', __FILE__) if Rails.env.development?
      end

      def log_level
        @log_level ||= Rails.env.production? ? :info : :debug
      end

      def colorize_logging
        @colorize_logging
      end

      def colorize_logging=(val)
        @colorize_logging = val
        Rails::LogSubscriber.colorize_logging = val
        self.generators.colorize_logging = val
      end

      def session_store(*args)
        if args.empty?
          case @session_store
          when :disabled
            nil
          when :active_record_store
            ActiveRecord::SessionStore
          when Symbol
            ActionDispatch::Session.const_get(@session_store.to_s.camelize)
          else
            @session_store
          end
        else
          @session_store = args.shift
          @session_options = args.shift || {}
        end
      end

    protected

      def session_options
        return @session_options unless @session_store == :cookie_store
        @session_options.merge(:secret => @secret_token)
      end

      def default_middleware_stack
        ActionDispatch::MiddlewareStack.new.tap do |middleware|
          middleware.use('::ActionDispatch::Static', lambda { Rails.public_path }, :if => lambda { serve_static_assets })
          middleware.use('::Rack::Lock', :if => lambda { !allow_concurrency })
          middleware.use('::Rack::Runtime')
          middleware.use('::Rails::Rack::Logger')
          middleware.use('::ActionDispatch::ShowExceptions', lambda { consider_all_requests_local }, :if => lambda { action_dispatch.show_exceptions })
          middleware.use("::ActionDispatch::RemoteIp", lambda { action_dispatch.ip_spoofing_check }, lambda { action_dispatch.trusted_proxies })
          middleware.use('::Rack::Sendfile', lambda { action_dispatch.x_sendfile_header })
          middleware.use('::ActionDispatch::Callbacks', lambda { !cache_classes })
          middleware.use('::ActionDispatch::Cookies')
          middleware.use(lambda { session_store }, lambda { session_options })
          middleware.use('::ActionDispatch::Flash', :if => lambda { session_store })
          middleware.use(lambda { metal_loader.build_middleware(metals) }, :if => lambda { metal_loader.metals.any? })
          middleware.use('ActionDispatch::ParamsParser')
          middleware.use('::Rack::MethodOverride')
          middleware.use('::ActionDispatch::Head')
        end
      end
    end
  end
end
