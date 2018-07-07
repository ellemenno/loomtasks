
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

require 'fileutils'
require 'rake/clean'

require File.join(File.dirname(__FILE__), 'rakefiles', 'support')
include LoomTasks


@global_loom_config = nil

LIBRARY = File.join('lib', 'build', "#{LoomTasks.const_lib_name}.loomlib")

def default_sdk
  global_config['default_sdk']
end

def global_config()
  @global_loom_config || (@global_loom_config = LoomTasks.parse_loom_config(LoomTasks.global_config_file))
end

def ensure_lib_uptodate(sdk_version)
  file_installed = File.join(LoomTasks.libs_path(sdk_version), "#{LoomTasks.const_lib_name}.loomlib")
  Rake::Task['lib:install'].invoke unless FileUtils.uptodate?(file_installed, [LIBRARY])
end

def compile_demo(dir, build_file, demo_config)
  sdk_version = demo_config['sdk_version']
  ensure_lib_uptodate(sdk_version)

  Dir.chdir(dir) do
    Dir.mkdir('bin') unless Dir.exists?('bin')
    cmd = "#{LoomTasks.lsc(sdk_version)} #{build_file}"
    try(cmd, "failed to compile .loom")
  end
end


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

task :default => [:list_targets]

task :list_targets => [:check_consts] do |t, args|
  a = "#{LoomTasks.const_lib_name} v#{LoomTasks.lib_version(const_lib_version_file)} Rakefile"
  b = "running on Ruby #{RUBY_VERSION}"
  puts "#{a} #{b}"
  system('rake -T')
  puts "(using loomtasks v#{LoomTasks::VERSION})"
end

task :check_consts do |t, args|
  LoomTasks.fail("please define the LIB_NAME constant before loading #{File.basename(__FILE__)}") unless LoomTasks.const_lib_name
  LoomTasks.fail("please define the LIB_VERSION_FILE constant before loading #{File.basename(__FILE__)}") unless LoomTasks.const_lib_version_file
end


Dir.glob(File.join(File.dirname(__FILE__), 'rakefiles', '*.rake')).each do |rakefile|
  # don't load rakefiles for non-existent modules
  dir = File.basename(rakefile).match(/loomlib_(.*)\.rake/)[1]
  load rakefile if Dir.exists?(dir)
end


desc [
  "shows usage and project info, optionally for a specific command",
  "usage: rake help",
  "   or: rake help <command>",
].join("\n")
task :help do |t, args|
  # avoid rake errors about undefined tasks; we want to pull args ourselves
  ARGV.each do |a|
    task a.to_sym do ; end
    Rake::Task[a.to_sym].clear
  end

  cmd = ARGV.fetch(1, nil)
  system("rake -D #{cmd}") if (cmd)
  system("rake -D") unless (cmd)

  puts "Please see the README for additional details."
end

desc [
  "sets the provided SDK version in the config files of lib, cli, gui, and test",
  "each config file can also be set independently, using the namespaced tasks provided",
  "available sdks can be listed with 'rake list_sdks'",
].join("\n")
task :sdk, [:id] do |t, args|
  args.with_defaults(:id => default_sdk)
  sdk_version = args.id
  lib_dir = LoomTasks.libs_path(sdk_version)

  LoomTasks.fail("no sdk named '#{sdk_version}' found in #{sdk_root}") unless (Dir.exists?(lib_dir))

  Rake::Task['lib:sdk'].invoke(sdk_version)
  Rake::Task['cli:sdk'].invoke(sdk_version)
  Rake::Task['gui:sdk'].invoke(sdk_version)
  Rake::Task['test:sdk'].invoke(sdk_version)

  puts "[#{t.name}] task completed, all loom.configs updated to #{sdk_version}"
end

desc [
  "lists loom sdk versions available use",
  "loom sdks are stored in #{LoomTasks.sdk_root}",
].join("\n")
task :list_sdks do |t, args|
  cmd = "ls -l1 #{LoomTasks.sdk_root}" unless windows?
  cmd = "dir /b #{LoomTasks.sdk_root}" if windows?
  system(cmd)
end
