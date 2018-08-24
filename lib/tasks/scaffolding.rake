require 'erb'
require 'fileutils'
require 'json'
require 'pathname'

require File.join(File.dirname(__FILE__), 'rakefiles', 'support')
include LoomTasks


def global_config_file
  File.join(Dir.home, '.loom', 'loom.config')
end

def default_loom_sdk
  JSON.parse(File.read(global_config_file))["default_sdk"]
end

def lib_name()
  @lib_name || LoomTasks.fail("no lib name defined")
end

def template_dir
  File.join(Dir.home, '.loom', 'tasks', 'templates')
end

def template_context()
  context = binding

  context.local_variable_set(:lib_name, lib_name)
  context.local_variable_set(:sdk_version, default_loom_sdk)

  context
end

def copy_from_template(dir, files)
  FileUtils.mkdir_p(dir)
  FileUtils.cp(files, dir)
end

def create_from_string(pathname, contents)
  FileUtils.mkdir_p(File.dirname(pathname))
  File.open(pathname, 'w+') { |f| f.write(contents) }
end

def create_from_template(pathname, template, binding)
  FileUtils.mkdir_p(File.dirname(pathname))
  File.open(pathname, 'w+') { |f| f.write(ERB.new(File.read(template)).result(binding)) }
end

def gitignore_pathname()
  File.join(Dir.pwd, '.gitignore')
end

def gitignore_template()
  File.join(template_dir, 'gitignore.erb')
end

def cli_wrapper_pathname()
  ext = windows? ? 'bat' : 'sh'
  File.join(Dir.pwd, 'cli', 'wrapper', "#{lib_name}.#{ext}")
end

def cli_wrapper_template()
  ext = windows? ? 'bat' : 'sh'
  File.join(template_dir, "cli_wrapper.#{ext}")
end

def demo_cli_pathname()
  File.join(Dir.pwd, 'cli', 'src', "#{lib_name}DemoCLI.ls")
end

def demo_cli_template()
  File.join(template_dir, 'LoomlibDemoCLI.ls.erb')
end

def demo_gui_pathname()
  File.join(Dir.pwd, 'gui', 'src', "#{lib_name}DemoGUI.ls")
end

def demo_gui_assets_pathname()
  File.join(Dir.pwd, 'gui', 'assets')
end

def demo_gui_assets()
  %w(
    pixeldroidMenuRegular-64.fnt
    pixeldroidMenuRegular-64.png
  ).map {|f| File.join(template_dir, f)}
end

def demo_gui_template()
  File.join(template_dir, 'LoomlibDemoGUI.ls.erb')
end

def doc_config_pathname()
  File.join(Dir.pwd, 'doc', 'src', '_config.yml')
end

def doc_config_template()
  File.join(template_dir, 'lsdoc_config.erb')
end

def doc_index_pathname()
  File.join(Dir.pwd, 'doc', 'src', 'index.md')
end

def doc_index_template()
  File.join(template_dir, 'lsdoc_index.erb')
end

def lib_testapp_pathname()
  File.join(Dir.pwd, 'test', 'src', 'app', "#{lib_name}Test.ls")
end

def lib_testapp_template()
  File.join(template_dir, 'LoomlibTest.ls.erb')
end

def lib_testspec_pathname()
  File.join(Dir.pwd, 'test', 'src', 'spec', "#{lib_name}Spec.ls")
end

def lib_testspec_template()
  File.join(template_dir, 'LoomlibSpec.ls.erb')
end

def loombuild_pathname(dir, name)
  File.join(Dir.pwd, dir, 'src', "#{name}.build")
end

def loombuild_contents(args, is_cli=false)
  name = args.fetch(:name)
  dir  = args.fetch(:outputDir)
  ref  = args.fetch(:references)
  src  = args.fetch(:sourcePath, ['.'])

  obj = {
    :name => name,
    :version => '1.0',
    :outputDir => dir,
    :references => ref,
    :modules => [
      {
        :name => name,
        :version => '1.0',
        :sourcePath => src,
      },
    ],
  }
  obj[:executable] = true if is_cli

  [
    JSON.pretty_generate(obj),
    "",
  ].join("\n")
end

def loombuild_demo_cli_contents()
  loombuild_contents({
    :name => "#{lib_name}DemoCLI",
    :outputDir => 'bin',
    :references => [ 'System', lib_name ],
    },
    true
  )
end

def loombuild_demo_gui_contents()
  loombuild_contents({
    :name => "#{lib_name}DemoGUI",
    :outputDir => 'bin',
    :references => [ 'System', 'Loom', lib_name ],
    },
    true
    )
end

def loombuild_lib_contents()
  loombuild_contents({
    :name => lib_name,
    :outputDir => 'build',
    :references => [ 'System' ],
  })
end

def loombuild_test_contents()
  loombuild_contents({
    :name => "#{lib_name}Test",
    :outputDir => 'bin',
    :references => [ 'System', 'Spec', lib_name ],
    :sourcePath => [ 'app', 'spec' ]
    },
    true
  )
end

def loomconfig_pathname(dir)
  File.join(Dir.pwd, dir, 'loom.config')
end

def loomconfig_cli_contents()
  [
    JSON.pretty_generate({ :sdk_version => default_loom_sdk() }),
    "",
  ].join("\n")
end

def loomconfig_gui_template()
  File.join(template_dir, 'loom_gui.config.erb')
end

def loomconfig_demo_contents()
  name = "#{lib_name}DemoGUI"

  [
    JSON.pretty_generate({
      :sdk_version => default_loom_sdk(),
      :display => {
        :width => 480,
        :height => 320,
        :title => name,
        :orientation => 'landscape',
      },
      :app_id => "com.yourcompany.#{name}",
      :app_name => name,
      :app_version => '0.0.0',
    }),
    "",
  ].join("\n")
end


def rakefile_pathname()
  File.join(Dir.pwd, 'Rakefile')
end

def rakefile_template()
  File.join(template_dir, 'Rakefile.erb')
end

def sourcefile_pathname()
  File.join(Dir.pwd, 'lib', 'src', "#{lib_name}.ls")
end

def sourcefile_template()
  File.join(template_dir, 'Loomlib.ls.erb')
end


task :default => [:usage]

task :usage do |t, args|
  this_file = File.basename(__FILE__)
  puts ''
  puts "#{this_file} v#{VERSION}: a utility to create a new loomlib directory structure"
  puts ''
  puts 'typically this is run from another directory, to bootstrap a new loomlib project there:'
  puts ''
  puts '$ cd MyLoomlib'
  puts "$ rake -f #{File.join(Dir.home, '.loom', 'tasks', this_file)} new:loomlib[MyLoomlib]"
  puts '$ rake'
end

namespace :new do

  task :gitignore do |t, args|
    context = template_context

    create_from_template(gitignore_pathname, gitignore_template, context)
  end

  task :rakefile do |t, args|
    context = template_context
    context.local_variable_set(:lib_name, lib_name)

    create_from_template(rakefile_pathname, rakefile_template, context)
  end

  task :cli do |t, args|
    name = "#{lib_name}DemoCLI"

    context = template_context

    create_from_string(loomconfig_pathname('cli'), loomconfig_cli_contents)
    create_from_string(loombuild_pathname('cli', name), loombuild_demo_cli_contents)
    create_from_template(demo_cli_pathname, demo_cli_template, context)
    create_from_template(cli_wrapper_pathname, cli_wrapper_template, context)
  end

  task :doc do |t, args|
    context = template_context

    create_from_template(doc_config_pathname, doc_config_template, context)
    create_from_template(doc_index_pathname, doc_index_template, context)
  end

  task :gui do |t, args|
    name = "#{lib_name}DemoGUI"

    context = template_context
    context.local_variable_set(:app_name, name)

    create_from_template(loomconfig_pathname('gui'), loomconfig_gui_template, context)
    create_from_string(loombuild_pathname('gui', name), loombuild_demo_gui_contents)
    create_from_template(demo_gui_pathname, demo_gui_template, context)
    copy_from_template(demo_gui_assets_pathname, demo_gui_assets)
  end

  task :lib do |t, args|
    context = template_context

    create_from_string(loomconfig_pathname('lib'), loomconfig_cli_contents)
    create_from_string(loombuild_pathname('lib', lib_name), loombuild_lib_contents)
    create_from_template(sourcefile_pathname, sourcefile_template, context)
  end

  task :test do |t, args|
    name = "#{lib_name}Test"

    context = template_context

    create_from_string(loomconfig_pathname('test'), loomconfig_cli_contents)
    create_from_string(loombuild_pathname('test', name), loombuild_test_contents)
    create_from_template(lib_testapp_pathname, lib_testapp_template, context)
    create_from_template(lib_testspec_pathname, lib_testspec_template, context)
  end

  task :scaffold => [:gitignore, :rakefile, :lib, :test, :cli, :gui, :doc]

  desc [
    "scaffolds the directories and files for a new loomlib project",
    "if no name argument is given, the current directory name is used",
    "creates a .gitignore file, rakefile, template library, test code, and docs",
    "this task assumes (but does not enforce) being run in an empty directory",
  ].join("\n")
  task :loomlib, [:name] do |t, args|
    args.with_defaults(:name => Pathname.new(Dir.pwd).basename.to_s)
    @lib_name = args.name

    Rake::Task['new:scaffold'].invoke()
    puts "project prepared to generate #{lib_name}.loomlib"
    puts "run `rake` to see available tasks"
  end

end
