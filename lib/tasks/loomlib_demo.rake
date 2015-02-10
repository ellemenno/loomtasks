
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# loomlib_demo.rake - adds support for a GUI demo of the loomlib
#
# usage
#   add the following to your project's Rakefile:
#
#   load(File.join(ENV['HOME'], '.loom', 'tasks', 'loomlib_demo.rake'))

require 'fileutils'

require File.join(File.dirname(__FILE__), 'support')
include LoomTasks

DEMO = "test/bin/#{const_lib_name}Demo.loom"

FileList['test/src/demo/*.ls'].each do |src|
  file DEMO => src
end

file DEMO => LIBRARY do |t, args|
  puts "[file] creating #{t.name}..."

  sdk_version = test_config['sdk_version']
  file_installed = "#{sdk_root}/#{sdk_version}/libs/#{const_lib_name}.loomlib"

  Rake::Task['lib:install'].invoke unless FileUtils.uptodate?(file_installed, [LIBRARY])

  Dir.chdir('test') do
    Dir.mkdir('bin') unless Dir.exists?('bin')
    cmd = "#{lsc(sdk_version)} #{const_lib_name}Demo.build"
    try(cmd, "failed to compile .loom")
  end

  puts ''
end

namespace :demo do

  desc [
    "builds #{const_lib_name}Demo.loom for #{test_config['sdk_version']} SDK",
    "the SDK is specified in test/loom.config",
    "you can change the SDK with rake set[sdk]",
    "the .loom binary is created in test/bin",
  ].join("\n")
  task :build => DEMO do |t, args|
    puts "[#{t.name}] task completed, find .loom in test/bin/"
    puts ''
  end

  desc [
    "launches #{const_lib_name}Demo.loom as a GUI app",
    "use this launcher if your demo application class extends loom.Application",
  ].join("\n")
  task :gui => DEMO do |t, args|
    puts "[#{t.name}] launching #{t.prerequisites[0]}..."

    sdk_version = test_config['sdk_version']

    Dir.chdir('test') do
      loomlib = "bin/#{const_lib_name}Demo.loom"
      abort("could not find '#{loomlib}'' to launch") unless File.exists?(loomlib)

      # loomlaunch expects to find Main.loom, so we make a launchable copy here
      FileUtils.cp(loomlib, 'bin/Main.loom')

      cmd = loomlaunch(sdk_version)
      try(cmd, "failed to launch .loom")
    end

    puts ''
  end

  desc [
    "executes #{const_lib_name}Demo.loom as a commandline app, with options",
    "use this launcher if your demo application class extends system.application.ConsoleApplication",
  ].join("\n")
  task :cli, [:options] => DEMO do |t, args|
    args.with_defaults(:options => '')
    puts "[#{t.name}] executing #{t.prerequisites[0]}..."

    sdk_version = test_config['sdk_version']

    cmd = "#{loomexec(sdk_version)} test/bin/#{const_lib_name}Demo.loom #{args.options}"
    try(cmd, "failed to run .loom")

    puts ''
  end

end
