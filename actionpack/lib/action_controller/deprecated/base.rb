module ActionController
  class Base
    class << self
      def deprecated_config_accessor(option, message = nil)
        deprecated_config_reader(option, message)
        deprecated_config_writer(option, message)
      end

      # This method has been moved to ActionDispatch::Request.filter_parameters
      def filter_parameter_logging(*args, &block)
        ActiveSupport::Deprecation.warn("Setting filter_parameter_logging in ActionController is deprecated and has no longer effect, please set 'config.filter_parameters' in config/application.rb instead", caller)
        filter = Rails.application.config.filter_parameters
        filter.concat(args)
        filter << block if block
        filter
      end

      def deprecated_config_reader(option, message = nil)
        message ||= "Reading #{option} directly from ActionController::Base is deprecated. " \
                    "Please read it from config.#{option}"

        self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{option}
            ActiveSupport::Deprecation.warn #{message.inspect}, caller
            config.#{option}
          end
        RUBY
      end

      def deprecated_config_writer(option, message = nil)
        message ||= "Setting #{option} directly on ActionController::Base is deprecated. " \
                    "Please set it on config.action_controller.#{option}"

        self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{option}=(val)
            ActiveSupport::Deprecation.warn #{message.inspect}, caller
            config.#{option} = val
          end
        RUBY
      end

      def consider_all_requests_local
        ActiveSupport::Deprecation.warn "ActionController::Base.consider_all_requests_local is deprecated, " <<
          "use Rails.application.config.consider_all_requests_local instead", caller
        Rails.application.config.consider_all_requests_local
      end

      def consider_all_requests_local=(value)
        ActiveSupport::Deprecation.warn "ActionController::Base.consider_all_requests_local= is deprecated. " <<
          "Please configure it on your application with config.consider_all_requests_local=", caller
        Rails.application.config.consider_all_requests_local = value
      end

      def allow_concurrency
        ActiveSupport::Deprecation.warn "ActionController::Base.allow_concurrency is deprecated, " <<
          "use Rails.application.config.allow_concurrency instead", caller
        Rails.application.config.allow_concurrency
      end

      def allow_concurrency=(value)
        ActiveSupport::Deprecation.warn "ActionController::Base.allow_concurrency= is deprecated. " <<
          "Please configure it on your application with config.allow_concurrency=", caller
        Rails.application.config.allow_concurrency = value
      end

      def ip_spoofing_check=(value)
        ActiveSupport::Deprecation.warn "ActionController::Base.ip_spoofing_check= is deprecated. " <<
          "Please configure it on your application with config.action_dispatch.ip_spoofing_check=", caller
        Rails.application.config.action_dispatch.ip_spoofing_check = value
      end

      def ip_spoofing_check
        ActiveSupport::Deprecation.warn "ActionController::Base.ip_spoofing_check is deprecated. " <<
          "Configuring ip_spoofing_check on the application configures a middleware.", caller
        Rails.application.config.action_dispatch.ip_spoofing_check
      end

      def cookie_verifier_secret=(value)
        ActiveSupport::Deprecation.warn "ActionController::Base.cookie_verifier_secret= is deprecated. " <<
          "Please configure it on your application with config.secret_token=", caller
      end

      def cookie_verifier_secret
        ActiveSupport::Deprecation.warn "ActionController::Base.cookie_verifier_secret is deprecated.", caller
      end

      def trusted_proxies=(value)
        ActiveSupport::Deprecation.warn "ActionController::Base.trusted_proxies= is deprecated. " <<
          "Please configure it on your application with config.action_dispatch.trusted_proxies=", caller
        Rails.application.config.action_dispatch.ip_spoofing_check = value
      end

      def trusted_proxies
        ActiveSupport::Deprecation.warn "ActionController::Base.trusted_proxies is deprecated. " <<
          "Configuring trusted_proxies on the application configures a middleware.", caller
        Rails.application.config.action_dispatch.ip_spoofing_check = value
      end

      def session(*args)
        ActiveSupport::Deprecation.warn(
          "Disabling sessions for a single controller has been deprecated. " +
          "Sessions are now lazy loaded. So if you don't access them, " +
          "consider them off. You can still modify the session cookie " +
          "options with request.session_options.", caller)
      end

      def session=(value)
        ActiveSupport::Deprecation.warn "ActionController::Base.session= is deprecated. " <<
          "Please configure it on your application with config.session_store :cookie_store, :key => '....'", caller
        if value.delete(:disabled)
          Rails.application.config.session_store :disabled
        else
          store = Rails.application.config.session_store
          Rails.application.config.session_store store, value
        end
      end

      # Controls the resource action separator
      def resource_action_separator
        @resource_action_separator ||= "/"
      end

      def resource_action_separator=(val)
        ActiveSupport::Deprecation.warn "ActionController::Base.resource_action_separator is deprecated and only " \
                                        "works with the deprecated router DSL."
        @resource_action_separator = val
      end

      def use_accept_header
        ActiveSupport::Deprecation.warn "ActionController::Base.use_accept_header doesn't do anything anymore. " \
                                        "The accept header is always taken into account."
      end

      def use_accept_header=(val)
        use_accept_header
      end
    end

    deprecated_config_writer :session_store
    deprecated_config_writer :session_options
    deprecated_config_accessor :relative_url_root, "relative_url_root is ineffective. Please stop using it"
    deprecated_config_accessor :assets_dir
    deprecated_config_accessor :javascripts_dir
    deprecated_config_accessor :stylesheets_dir

    delegate :consider_all_requests_local, :consider_all_requests_local=,
             :allow_concurrency, :allow_concurrency=, :to => :"self.class"
  end
end