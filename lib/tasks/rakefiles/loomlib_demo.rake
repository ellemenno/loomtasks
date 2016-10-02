
require 'fileutils'

require File.join(File.dirname(__FILE__), 'support')
include LoomTasks


@cli_loom_config = nil
@gui_loom_config = nil

def ensure_lib_uptodate(sdk_version)
  file_installed = File.join(LoomTasks::libs_path(sdk_version), "#{LoomTasks::const_lib_name}.loomlib")
  Rake::Task['lib:install'].invoke unless FileUtils.uptodate?(file_installed, [LIBRARY])
end

def compile_demo(dir, build_file, demo_config)
  sdk_version = demo_config['sdk_version']
  ensure_lib_uptodate(sdk_version)

  Dir.chdir(dir) do
    Dir.mkdir('bin') unless Dir.exists?('bin')
    cmd = "#{LoomTasks::lsc(sdk_version)} #{build_file}"
    try(cmd, "failed to compile .loom")
  end
end

def cli_config()
  @cli_loom_config || (@cli_loom_config = LoomTasks::parse_loom_config(cli_config_file))
end

def gui_config()
  @gui_loom_config || (@gui_loom_config = LoomTasks::parse_loom_config(gui_config_file))
end

def cli_config_file()
  File.join('cli', 'loom.config')
end

def gui_config_file()
  File.join('gui', 'loom.config')
end

def write_cli_config(config)
  LoomTasks::write_loom_config(cli_config_file, config)
end

def write_gui_config(config)
  LoomTasks::write_loom_config(gui_config_file, config)
end

DEMO_CLI = File.join('cli', 'bin', "#{LoomTasks::const_lib_name}DemoCLI.loom")
DEMO_GUI = File.join('gui', 'bin', "#{LoomTasks::const_lib_name}DemoGUI.loom")

[
  File.join('cli', 'bin', '**'),
  File.join('gui', 'bin', '**'),
].each { |f| CLEAN << f }
[
  File.join('cli', 'bin'),
  File.join('gui', 'bin'),
].each { |f| CLOBBER << f }

file DEMO_CLI => LIBRARY do |t, args|
  puts "[file] creating #{t.name}..."

  compile_demo('cli', "#{LoomTasks::const_lib_name}DemoCLI.build", cli_config)

  puts ''
end

FileList[File.join('cli', 'src', '**', '*.ls')].each do |src|
  file DEMO_CLI => src
end

file DEMO_GUI => LIBRARY do |t, args|
  puts "[file] creating #{t.name}..."

  compile_demo('gui', "#{LoomTasks::const_lib_name}DemoGUI.build", gui_config)

  puts ''
end

FileList[File.join('gui', 'src', '**', '*.ls')].each do |src|
  file DEMO_GUI => src
end

namespace :cli do

  desc [
    "builds #{DEMO_CLI} for #{cli_config['sdk_version']} SDK",
    "the SDK is specified in cli/loom.config",
    "you can change the SDK with rake set[sdk]",
    "the .loom binary is created in cli/bin",
    "you can remove this task from the list with Rake::Task['cli:build'].clear",
  ].join("\n")
  task :build => DEMO_CLI do |t, args|
    puts "[#{t.name}] task completed, find .loom in cli/bin/"
    puts ''
  end

  desc [
    "executes #{DEMO_CLI} as a commandline app, with options, if provided",
    "your demo application class should extend system.application.ConsoleApplication",
    "you can remove this task from the list with Rake::Task['cli:run'].clear",
  ].join("\n")
  task :run, [:options] => DEMO_CLI do |t, args|
    args.with_defaults(:options => '')

    sdk_version = cli_config['sdk_version']
    binary = t.prerequisites[0]
    main = File.join('cli', LoomTasks::main_binary)

    puts "[#{t.name}] executing #{binary} as #{main}..."
    abort("could not find '#{binary}' to launch") unless File.exists?(binary)

    # loomexec expects to find bin/Main.loom, so we make a launchable copy there
    FileUtils.cp(binary, main)

    Dir.chdir('cli') do
      cmd = "#{LoomTasks::loomexec(sdk_version)} #{args.options}"
      try(cmd, "failed to exec .loom")
    end

    puts ''
  end

  desc [
    "sets the provided SDK version into #{cli_config_file}",
    "this updates #{cli_config_file} to define which SDK will compile the test apps",
  ].join("\n")
  task :sdk, [:id] do |t, args|
    args.with_defaults(:id => default_sdk)
    sdk_version = args.id
    lib_dir = LoomTasks::libs_path(sdk_version)

    fail("no sdk named '#{sdk_version}' found in #{sdk_root}") unless (Dir.exists?(lib_dir))

    cli_config['sdk_version'] = sdk_version
    write_cli_config(cli_config)

    puts "[#{t.name}] task completed, sdk updated to #{sdk_version}"
    puts ''
  end

end

namespace :gui do

  desc [
    "builds #{DEMO_GUI} for #{gui_config['sdk_version']} SDK",
    "the SDK is specified in gui/loom.config",
    "you can change the SDK with rake set[sdk]",
    "the .loom binary is created in gui/bin",
    "you can remove this task from the list with Rake::Task['gui:build'].clear",
  ].join("\n")
  task :build => DEMO_GUI do |t, args|
    puts "[#{t.name}] task completed, find .loom in gui/bin/"
    puts ''
  end

  desc [
    "launches #{DEMO_GUI} as a GUI app",
    "your demo application class should extend loom.Application",
    "you can remove this task from the list with Rake::Task['gui:run'].clear",
  ].join("\n")
  task :run => DEMO_GUI do |t, args|
    sdk_version = gui_config['sdk_version']
    binary = t.prerequisites[0]
    main = File.join('gui', LoomTasks::main_binary)

    puts "[#{t.name}] executing #{binary} as #{main}..."
    abort("could not find '#{binary}' to launch") unless File.exists?(binary)

    # loomlaunch expects to find bin/Main.loom, so we make a launchable copy here
    FileUtils.cp(binary, main)

    Dir.chdir('gui') do
      # capture the interrupt signal from a quit app
      begin
        cmd = LoomTasks::loomlaunch(sdk_version)
        try(cmd, "failed to launch .loom")
      rescue Exception => e
        puts ' (quit)'
      end
    end
  end

  desc [
    "sets the provided SDK version into #{gui_config_file}",
    "this updates #{gui_config_file} to define which SDK will compile the test apps",
  ].join("\n")
  task :sdk, [:id] do |t, args|
    args.with_defaults(:id => default_sdk)
    sdk_version = args.id
    lib_dir = LoomTasks::libs_path(sdk_version)

    fail("no sdk named '#{sdk_version}' found in #{sdk_root}") unless (Dir.exists?(lib_dir))

    gui_config['sdk_version'] = sdk_version
    write_gui_config(gui_config)

    puts "[#{t.name}] task completed, sdk updated to #{sdk_version}"
    puts ''
  end

end

desc [
  "shorthand for rake cli:run",
].join("\n")
task :cli, [:options] do |t, args|
  Rake::Task['cli:run'].invoke(*args)
end

desc [
  "shorthand for rake gui:run",
].join("\n")
task :gui => 'gui:run'
