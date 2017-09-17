
require 'fileutils'

require File.join(File.dirname(__FILE__), 'support')
include LoomTasks


@cli_loom_config = nil

def cli_config()
  @cli_loom_config || (@cli_loom_config = LoomTasks.parse_loom_config(cli_config_file))
end

def cli_config_file()
  File.join('cli', 'loom.config')
end

def write_cli_config(config)
  LoomTasks.write_loom_config(cli_config_file, config)
end

DEMO_CLI = File.join('cli', 'bin', "#{LoomTasks.const_lib_name}DemoCLI.loom")

[
  File.join('cli', 'bin', '**'),
].each { |f| CLEAN << f }
[
  File.join('cli', 'bin'),
].each { |f| CLOBBER << f }

file DEMO_CLI => LIBRARY do |t, args|
  puts "[file] creating #{t.name}..."
  compile_demo('cli', "#{LoomTasks.const_lib_name}DemoCLI.build", cli_config)
end

FileList[File.join('cli', 'src', '**', '*.ls')].each do |src|
  file DEMO_CLI => src
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
    main = File.join('cli', LoomTasks.main_binary)

    puts "[#{t.name}] executing #{binary} as #{main}..."
    abort("could not find '#{binary}' to launch") unless File.exists?(binary)

    # loomexec expects to find bin/Main.loom, so we make a launchable copy there
    FileUtils.cp(binary, main)

    Dir.chdir('cli') do
      cmd = LoomTasks.loomexec(sdk_version, args.options)
      try(cmd, "failed to exec .loom")
    end
  end

  desc [
    "sets the provided SDK version into #{cli_config_file}",
    "this updates #{cli_config_file} to define which SDK will compile the test apps",
    "available sdks can be listed with 'rake list_sdks'",
  ].join("\n")
  task :sdk, [:id] do |t, args|
    args.with_defaults(:id => default_sdk)
    sdk_version = args.id
    lib_dir = LoomTasks.libs_path(sdk_version)

    fail("no sdk named '#{sdk_version}' found in #{sdk_root}") unless (Dir.exists?(lib_dir))

    cli_config['sdk_version'] = sdk_version
    write_cli_config(cli_config)

    puts "[#{t.name}] task completed, sdk updated to #{sdk_version}"
  end

end

desc [
  "shorthand for rake cli:run",
].join("\n")
task :cli, [:options] do |t, args|
  Rake::Task['cli:run'].invoke(*args)
end
