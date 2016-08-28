require 'erb'
require 'fileutils'
require 'json'
require 'pathname'

require File.join(File.dirname(__FILE__), 'support')
include LoomTasks


def global_config_file
  File.join(Dir.home, '.loom', 'loom.config')
end

def default_loom_sdk
  JSON.parse(File.read(global_config_file))["default_sdk"]
end

def lib_name()
  @lib_name || fail("no lib name defined")
end

def template_dir
  File.join(Dir.home, '.loom', 'tasks', 'templates')
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

def loombuild_pathname(dir)
  name = (dir == 'test') ? "#{lib_name}Test.build" : "#{lib_name}.build"
  File.join(Dir.pwd, dir, 'src', name)
end

def loombuild_contents(dir)
  is_test = (dir == 'test')

  name = is_test ? "#{lib_name}Test" : lib_name
  dir = is_test ? 'bin' : 'build'
  ref = is_test ? [ 'System', 'Spec', lib_name ] : [ 'System' ]
  src = is_test ? [ 'app', 'spec' ] : [ '.' ]

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
  obj[:executable] = true if is_test

  [
    JSON.pretty_generate(obj),
    "",
  ].join("\n")
end

def loomconfig_pathname(dir)
  File.join(Dir.pwd, dir, 'loom.config')
end

def loomconfig_contents()
  [
    JSON.pretty_generate({ :sdk_version => default_loom_sdk() }),
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


task :default => :usage

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
    create_from_template(gitignore_pathname, gitignore_template, binding)
  end

  task :rakefile do |t, args|
    create_from_template(rakefile_pathname, rakefile_template, binding)
  end

  task :libdir do |t, args|
    create_from_string(loomconfig_pathname('lib'), loomconfig_contents)
    create_from_string(loombuild_pathname('lib'), loombuild_contents('lib'))
    create_from_template(sourcefile_pathname, sourcefile_template, binding)
  end

  task :testdir do |t, args|
    create_from_string(loomconfig_pathname('test'), loomconfig_contents)
    create_from_string(loombuild_pathname('test'), loombuild_contents('test'))
    create_from_template(lib_testapp_pathname, lib_testapp_template, binding)
    create_from_template(lib_testspec_pathname, lib_testspec_template, binding)
  end

  task :scaffold => [:gitignore, :rakefile, :libdir, :testdir]

  desc [
    "scaffolds the directories and files for a new loomlib project",
    "if no name argument is given, the current directory name is used",
    "creates a .gitignore file, rakefile, and template library and test code",
    "this code assumes (but does not enforce) being run in an empty directory",
  ].join("\n")
  task :loomlib, [:name] do |t, args|
    args.with_defaults(:name => Pathname.new(Dir.pwd).basename.to_s)
    @lib_name = args.name

    Rake::Task['new:scaffold'].invoke()
    puts "project prepared to generate #{lib_name}.loomlib"
    puts "run `rake` to see available tasks"
  end

end
