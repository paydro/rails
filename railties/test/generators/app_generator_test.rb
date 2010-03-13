require 'abstract_unit'
require 'generators/generators_test_helper'
require 'generators/rails/app/app_generator'

class AppGeneratorTest < Rails::Generators::TestCase
  include GeneratorsTestHelper
  arguments [destination_root]

  def setup
    super
    Rails::Generators::AppGenerator.instance_variable_set('@desc', nil)
    @bundle_command = File.basename(Thor::Util.ruby_command).sub(/ruby/, 'bundle')
  end

  def teardown
    super
    Rails::Generators::AppGenerator.instance_variable_set('@desc', nil)
  end

  def test_application_skeleton_is_created
    run_generator

    %w(
      app/controllers
      app/helpers
      app/models
      app/views/layouts
      config/environments
      config/initializers
      config/locales
      db
      doc
      lib
      lib/tasks
      log
      public/images
      public/javascripts
      public/stylesheets
      script/rails
      test/fixtures
      test/functional
      test/integration
      test/performance
      test/unit
      vendor
      vendor/plugins
      tmp/sessions
      tmp/sockets
      tmp/cache
      tmp/pids
    ).each{ |path| assert_file path }
  end

  def test_name_collision_raises_an_error
    content = capture(:stderr){ run_generator [File.join(destination_root, "generate")] }
    assert_equal "Invalid application name generate. Please give a name which does not match one of the reserved rails words.\n", content
  end

  def test_invalid_database_option_raises_an_error
    content = capture(:stderr){ run_generator([destination_root, "-d", "unknown"]) }
    assert_match /Invalid value for \-\-database option/, content
  end

  def test_invalid_application_name_raises_an_error
    content = capture(:stderr){ run_generator [File.join(destination_root, "43-things")] }
    assert_equal "Invalid application name 43-things. Please give a name which does not start with numbers.\n", content
  end

  def test_application_name_raises_an_error_if_name_already_used_constant
    %w{ String Hash Class Module Set Symbol }.each do |ruby_class|
      content = capture(:stderr){ run_generator [File.join(destination_root, ruby_class)] }
      assert_equal "Invalid application name #{ruby_class}, constant #{ruby_class} is already in use. Please choose another application name.\n", content
    end
  end

  def test_invalid_application_name_is_fixed
    run_generator [File.join(destination_root, "things-43")]
    assert_file "things-43/config/environment.rb", /Things43::Application\.initialize!/
    assert_file "things-43/config/application.rb", /^module Things43$/
  end

  def test_application_names_are_not_singularized
    run_generator [File.join(destination_root, "hats")]
    assert_file "hats/config/environment.rb", /Hats::Application\.initialize!/
  end

  def test_config_database_is_added_by_default
    run_generator
    assert_file "config/database.yml", /sqlite3/
    assert_file "Gemfile", /^gem\s+["']sqlite3-ruby["'],\s+:require\s+=>\s+["']sqlite3["']$/
  end

  def test_config_another_database
    run_generator([destination_root, "-d", "mysql"])
    assert_file "config/database.yml", /mysql/
    assert_file "Gemfile", /^gem\s+["']mysql["']$/
  end

  def test_config_database_is_not_added_if_skip_activerecord_is_given
    run_generator [destination_root, "--skip-activerecord"]
    assert_no_file "config/database.yml"
  end

  def test_activerecord_is_removed_from_frameworks_if_skip_activerecord_is_given
    run_generator [destination_root, "--skip-activerecord"]
    assert_file "config/application.rb", /#\s+require\s+["']active_record\/railtie["']/
  end

  def test_fixtures_not_added_if_skip_activerecord_is_given
    run_generator [destination_root, "--skip-activerecord"]
    assert_no_file "test/fixtures"
    assert_file "test/test_helper.rb", %Q[ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...
end
]
  end

  def test_prototype_and_test_unit_are_added_by_default
    run_generator
    assert_file "public/javascripts/prototype.js"
    assert_file "test"
  end

  def test_prototype_and_test_unit_are_skipped_if_required
    run_generator [destination_root, "--skip-prototype", "--skip-testunit"]
    assert_no_file "public/javascripts/prototype.js"
    assert_file "public/javascripts"
    assert_no_file "test"
  end

  def test_shebang_is_added_to_rails_file
    run_generator [destination_root, "--ruby", "foo/bar/baz"]
    assert_file "script/rails", /#!foo\/bar\/baz/
  end

  def test_shebang_when_is_the_same_as_default_use_env
    run_generator [destination_root, "--ruby", Thor::Util.ruby_command]
    assert_file "script/rails", /#!\/usr\/bin\/env/
  end

  def test_template_from_dir_pwd
    FileUtils.cd(Rails.root)
    assert_match /It works from file!/, run_generator([destination_root, "-m", "lib/template.rb"])
  end

  def test_template_raises_an_error_with_invalid_path
    content = capture(:stderr){ run_generator([destination_root, "-m", "non/existant/path"]) }
    assert_match /The template \[.*\] could not be loaded/, content
    assert_match /non\/existant\/path/, content
  end

  def test_template_is_executed_when_supplied
    path = "http://gist.github.com/103208.txt"
    template = %{ say "It works!" }
    template.instance_eval "def read; self; end" # Make the string respond to read

    generator([destination_root], :template => path).expects(:open).with(path).returns(template)
    assert_match /It works!/, silence(:stdout){ generator.invoke }
  end

  def test_usage_read_from_file
    File.expects(:read).returns("USAGE FROM FILE")
    assert_equal "USAGE FROM FILE", Rails::Generators::AppGenerator.desc
  end

  def test_default_usage
    File.expects(:exist?).returns(false)
    assert_match /Create rails files for app generator/, Rails::Generators::AppGenerator.desc
  end

  def test_default_namespace
    assert_match "rails:app", Rails::Generators::AppGenerator.namespace
  end

  def test_file_is_added_for_backwards_compatibility
    action :file, 'lib/test_file.rb', 'heres test data'
    assert_file 'lib/test_file.rb', 'heres test data'
  end

  def test_dev_option
    generator([destination_root], :dev => true).expects(:run).with("#{@bundle_command} install")
    silence(:stdout){ generator.invoke }
    rails_path = File.expand_path('../../..', Rails.root)
    assert_file 'Gemfile', /^gem\s+["']rails["'],\s+:path\s+=>\s+["']#{Regexp.escape(rails_path)}["']$/
  end

  def test_edge_option
    generator([destination_root], :edge => true).expects(:run).with("#{@bundle_command} install")
    silence(:stdout){ generator.invoke }
    assert_file 'Gemfile', /^gem\s+["']rails["'],\s+:git\s+=>\s+["']#{Regexp.escape("git://github.com/rails/rails.git")}["']$/
  end

  protected

    def action(*args, &block)
      silence(:stdout){ generator.send(*args, &block) }
    end

end
