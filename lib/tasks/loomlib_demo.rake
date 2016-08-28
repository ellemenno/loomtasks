
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


DEMO = File.join('test', 'bin', "#{const_lib_name}Demo.loom")

FileList[File.join('test', 'src', 'demo', '*.ls')].each do |src|
  file DEMO => src
end

file DEMO => LIBRARY do |t, args|
  puts "[file] creating #{t.name}..."

  sdk_version = test_config['sdk_version']
  file_installed = File.join(sdk_root, sdk_version, 'libs', "#{lib_file}")

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
    "builds #{DEMO} for #{test_config['sdk_version']} SDK",
    "the SDK is specified in test/loom.config",
    "you can change the SDK with rake set[sdk]",
    "the .loom binary is created in test/bin",
  ].join("\n")
  task :build => DEMO do |t, args|
    puts "[#{t.name}] task completed, find .loom in test/bin/"
    puts ''
  end

  desc [
    "launches #{DEMO} as a GUI app",
    "use this launcher if your demo application class extends loom.Application",
    "if your demo is a cli app, remove this task from the list with Rake::Task['demo:gui'].clear",
  ].join("\n")
  task :gui => DEMO do |t, args|
    sdk_version = test_config['sdk_version']

    puts "[#{t.name}] launching #{DEMO} as #{main_binary}..."
    abort("could not find '#{DEMO}' to launch") unless File.exists?(DEMO)

    # loomlaunch expects to find bin/Main.loom, so we make a launchable copy here
    Dir.mkdir(bin_dir) unless Dir.exists?(bin_dir)
    FileUtils.cp(DEMO, main_binary)

    # capture the interrupt signal from a quit app
    begin
      cmd = loomlaunch(sdk_version)
      try(cmd, "failed to launch .loom")
    rescue Exception => e
      puts ' (quit)'
    end
  end

  desc [
    "executes #{DEMO} as a commandline app, with options, if provided",
    "use this launcher if your demo application class extends system.application.ConsoleApplication",
    "if your demo is a gui app, remove this task from the list with Rake::Task['demo:cli'].clear",
  ].join("\n")
  task :cli, [:options] => DEMO do |t, args|
    args.with_defaults(:options => '')

    sdk_version = test_config['sdk_version']

    puts "[#{t.name}] executing #{DEMO} as #{main_binary}..."
    abort("could not find '#{DEMO}' to launch") unless File.exists?(DEMO)

    # loomexec expects to find bin/Main.loom, so we make a launchable copy there
    Dir.mkdir(bin_dir) unless Dir.exists?(bin_dir)
    FileUtils.cp(DEMO, main_binary)

    cmd = "#{loomexec(sdk_version)} #{args.options}"
    try(cmd, "failed to exec .loom")

    puts ''
  end

end
