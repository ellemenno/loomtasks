
require 'fileutils'

require File.join(File.dirname(__FILE__), 'support')
include LoomTasks


@gui_loom_config = nil

def gui_config()
  @gui_loom_config || (@gui_loom_config = LoomTasks.parse_loom_config(gui_config_file))
end

def gui_config_file()
  File.join('gui', 'loom.config')
end

def write_gui_config(config)
  LoomTasks.write_loom_config(gui_config_file, config)
end

DEMO_GUI = File.join('gui', 'bin', "#{LoomTasks.const_lib_name}DemoGUI.loom")

[
  File.join('gui', 'bin', '**'),
].each { |f| CLEAN << f }
[
  File.join('gui', 'bin'),
].each { |f| CLOBBER << f }

file DEMO_GUI => LIBRARY do |t, args|
  puts "[file] creating #{t.name}..."
  compile_demo('gui', "#{LoomTasks.const_lib_name}DemoGUI.build", gui_config)
end

FileList[
  File.join('gui', 'loom.config'),
  File.join('gui', 'src', '*.build'),
  File.join('gui', 'src', '**', '*.ls'),
].each do |src|
  file DEMO_GUI => src
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
  end

  desc [
    "launches #{DEMO_GUI} as a GUI app",
    "your demo application class should extend loom.Application",
    "you can remove this task from the list with Rake::Task['gui:run'].clear",
  ].join("\n")
  task :run => DEMO_GUI do |t, args|
    sdk_version = gui_config['sdk_version']
    binary = t.prerequisites[0]
    main = File.join('gui', LoomTasks.main_binary)

    puts "[#{t.name}] executing #{binary} as #{main}..."
    abort("could not find '#{binary}' to launch") unless File.exists?(binary)

    # loomlaunch expects to find bin/Main.loom, so we make a launchable copy here
    FileUtils.cp(binary, main)

    Dir.chdir('gui') do
      # capture the interrupt signal from a quit app
      begin
        cmd = LoomTasks.loomlaunch(sdk_version)
        try(cmd, "failed to launch .loom")
      rescue Exception => e
        puts ' (quit)'
      end
    end
  end

  desc [
    "sets the provided SDK version into #{gui_config_file}",
    "this updates #{gui_config_file} to define which SDK will compile the test apps",
    "available sdks can be listed with 'rake list_sdks'",
  ].join("\n")
  task :sdk, [:id] do |t, args|
    args.with_defaults(:id => default_sdk)
    sdk_version = args.id
    lib_dir = LoomTasks.libs_path(sdk_version)

    LoomTasks.fail("no sdk named '#{sdk_version}' found in #{sdk_root}") unless (Dir.exists?(lib_dir))

    gui_config['sdk_version'] = sdk_version
    write_gui_config(gui_config)

    puts "[#{t.name}] task completed, sdk updated to #{sdk_version}"
  end

end

desc [
  "shorthand for rake gui:run",
].join("\n")
task :gui => 'gui:run'
