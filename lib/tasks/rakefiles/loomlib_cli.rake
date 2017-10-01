
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

def cli_wrapper()
  ext = windows? ? 'bat' : 'sh'
  File.join('cli', 'wrapper', "#{LoomTasks.const_lib_name}.#{ext}")
end

def cli_default_path_dir()
  File.join(Dir.home, 'bin')
end

def cli_default_bin_dir()
  File.join(Dir.home, '.loom', LoomTasks.const_lib_name)
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
    "installs an executable copy of #{DEMO_CLI} on the system",
    "the binary is renamed 'Main.loom' and stored under #{cli_default_bin_dir}; override with :b",
    "a wrapper script is installed on the path at #{cli_default_path_dir}; override with :p",
  ].join("\n")
  task :install, [:b, :p] => DEMO_CLI do |t, args|
    args.with_defaults(
      :b => cli_default_bin_dir,
      :p => cli_default_path_dir,
    )

    sdk_version = cli_config['sdk_version']
    loomexec = LoomTasks.loomexec(sdk_version)
    binary = t.prerequisites[0]

    cli_bin_dir = args.b
    cli_path_dir = args.p
    target_bin = File.join(cli_bin_dir, LoomTasks.main_binary)
    target_bin_dir = File.dirname(target_bin)
    target_exe = File.join(cli_bin_dir, LoomTasks.const_lib_name)
    target_wrapper = File.join(cli_path_dir, LoomTasks.const_lib_name)

    if (Dir.exists?(cli_bin_dir))
      puts "[#{t.name}] removing existing #{cli_bin_dir}..."
      FileUtils.rm_r(cli_bin_dir)
    end
    puts "[#{t.name}] creating #{target_bin_dir}..."
    FileUtils.mkdir_p(target_bin_dir) unless Dir.exists?(target_bin_dir)

    puts "[#{t.name}] copying #{binary} into #{target_bin}..."
    fail("could not find '#{binary}' to copy") unless File.exists?(binary)
    FileUtils.cp(binary, target_bin)

    puts "[#{t.name}] copying #{loomexec} into #{target_exe}..."
    fail("could not find '#{loomexec}' to copy") unless File.exists?(loomexec)
    FileUtils.cp(loomexec, target_exe)

    puts "[#{t.name}] copying #{cli_wrapper} into #{target_wrapper}..."
    fail("could not find '#{cli_wrapper}' to copy") unless File.exists?(cli_wrapper)
    FileUtils.cp(cli_wrapper, target_wrapper)
    FileUtils.chmod('u=wrx,go=rx', target_wrapper) # 755 on wrapper script to be executable for all, editable by user

    puts "[#{t.name}] task completed, #{LoomTasks.const_lib_name} installed for use"
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

    LoomTasks.fail("no sdk named '#{sdk_version}' found in #{sdk_root}") unless (Dir.exists?(lib_dir))

    cli_config['sdk_version'] = sdk_version
    write_cli_config(cli_config)

    puts "[#{t.name}] task completed, sdk updated to #{sdk_version}"
  end

  desc [
    "uninstalls the path executable #{LoomTasks.const_lib_name}",
    "the executable directory '#{cli_default_bin_dir}' is removed; override with :bin_dir",
    "the wrapper shell script is removed from #{cli_default_path_dir}; override with :p",
  ].join("\n")
  task :uninstall, [:b, :p] do |t, args|
    args.with_defaults(
      :b => cli_default_bin_dir,
      :p => cli_default_path_dir,
    )
    sdk_version = lib_config['sdk_version']
    sdk_dir = LoomTasks.sdk_root(sdk_version)

    cli_bin_dir = args.b
    cli_path_dir = args.p

    if (Dir.exists?(cli_bin_dir))
      FileUtils.rm_r(cli_bin_dir)
      puts "[#{t.name}] task completed, #{cli_bin_dir} removed"
    else
      puts "[#{t.name}] nothing to do; no #{cli_bin_dir} found"
    end

    installed_wrapper = File.join(cli_path_dir, LoomTasks.const_lib_name)
    if (File.exists?(installed_wrapper))
      FileUtils.rm_r(installed_wrapper)
      puts "[#{t.name}] task completed, #{LoomTasks.const_lib_name} removed from #{cli_path_dir}"
    else
      puts "[#{t.name}] nothing to do; no #{LoomTasks.const_lib_name} found in #{cli_path_dir}"
    end
  end

end

desc [
  "shorthand for rake cli:run",
].join("\n")
task :cli, [:options] do |t, args|
  Rake::Task['cli:run'].invoke(*args)
end
