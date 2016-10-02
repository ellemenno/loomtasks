
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# loomlib.rake - common Rake tasks for loomlib projects
#
# usage
#   add the following to your project's Rakefile:
#
#   load(File.join(ENV['HOME'], '.loom', 'tasks', 'loomlib.rake'))
#
#   starting a new project and don't have a rake file?
#   use the scaffolding tasks to get set up:
#
#   rake -f ~/.loom/tasks/scaffolding.rake new:loomlib[MyLibName]

require 'etc'
require 'fileutils'
require 'json'
require 'rake/clean'

require File.join(File.dirname(__FILE__), 'rakefiles', 'support')
include LoomTasks


@global_loom_config = nil

def default_sdk
  global_config['default_sdk']
end

def global_config()
  @global_loom_config || (@global_loom_config = LoomTasks::parse_loom_config(LoomTasks::global_config_file))
end

LIBRARY = File.join('lib', 'build', "#{LoomTasks::const_lib_name}.loomlib")

Dir.glob(File.join(File.dirname(__FILE__), 'rakefiles', '*.rake')).each { |r| load r }

[File.join('releases', '**')].each { |f| CLEAN << f }
Rake::Task[:clean].clear_comments()
Rake::Task[:clean].add_description([
  "removes intermediate files to ensure a clean build",
  "running now would delete the following:\n  #{CLEAN.resolve.join("\n  ")}",
].join("\n"))

['releases'].each { |f| CLOBBER << f }
Rake::Task[:clobber].enhance(['lib:uninstall'])
Rake::Task[:clobber].clear_comments()
Rake::Task[:clobber].add_description([
  "removes all generated artifacts to restore project to checkout-like state",
  "uninstalls the library from the current lib sdk",
  "removes the following folders:\n  #{CLOBBER.join("\n  ")}",
].join("\n"))

task :default => :list_targets

task :list_targets => :check_consts do |t, args|
  a = "#{LoomTasks::const_lib_name} v#{LoomTasks::lib_version(const_lib_version_file)} Rakefile"
  b = "running on Ruby #{RUBY_VERSION}"
  puts "#{a} #{b}"
  system("rake -T")
  puts "(using loomtasks v#{LoomTasks::VERSION})"
  puts ''
  puts 'use `rake -D` for more detailed task descriptions'
  puts ''
end

task :check_consts do |t, args|
  fail("please define the LIB_NAME constant before loading #{File.basename(__FILE__)}") unless LoomTasks::const_lib_name
  fail("please define the LIB_VERSION_FILE constant before loading #{File.basename(__FILE__)}") unless LoomTasks::const_lib_version_file
end


# namespace :set do

#   desc [
#     "sets the provided SDK version into #{lib_config_file} and #{test_config_file}",
#     "this updates #{lib_config_file} to define which SDK will compile the loomlib and be the install target",
#     "this updates #{test_config_file} to define which SDK will compile the test app and demo app",
#   ].join("\n")
#   task :sdk, [:id] => 'lib:uninstall' do |t, args|
#     args.with_defaults(:id => default_sdk)
#     sdk_version = args.id
#     lib_dir = libs_path(sdk_version)

#     fail("no sdk named '#{sdk_version}' found in #{sdk_root}") unless (Dir.exists?(lib_dir))

#     lib_config['sdk_version'] = sdk_version
#     test_config['sdk_version'] = sdk_version

#     write_lib_config(lib_config)
#     write_test_config(test_config)

#     puts "[#{t.name}] task completed, sdk updated to #{sdk_version}"
#     puts ''
#   end

#   desc [
#     "sets the library version number into #{lib_build_file} and #{lib_version_file}",
#     "#{lib_version_file} is expected to have a line matching:",
#     "#{lib_version_regex.to_s}",
#   ].join("\n")
#   task :version, [:v] do |t, args|
#     args.with_defaults(:v => '1.0.0')
#     lib_version = args.v

#     lib_build_config['version'] = lib_version
#     lib_build_config['modules'].first['version'] = lib_version

#     write_lib_build_config(lib_build_config)
#     update_lib_version(lib_version)

#     puts "[#{t.name}] task completed, lib version updated to #{lib_version}"
#     puts ''
#   end
# end

desc [
  "show detailed usage and project info",
].join("\n")
task :help do |t, args|
  system("rake -D")

  puts "Please see the README for additional details."
  puts ''
end
