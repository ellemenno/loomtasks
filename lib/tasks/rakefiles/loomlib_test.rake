
require 'fileutils'

require File.join(File.dirname(__FILE__), 'support')
include LoomTasks


@test_loom_config = nil

def test_config_file()
  File.join('test', 'loom.config')
end

def test_config()
  @test_loom_config || (@test_loom_config = LoomTasks.parse_loom_config(test_config_file))
end

def write_test_config(config)
  LoomTasks.write_loom_config(test_config_file, config)
end

TEST = File.join('test', 'bin', "#{LoomTasks.const_lib_name}Test.loom")

[
  File.join('test', 'bin', '**'),
  'TEST-*.xml',
].each { |f| CLEAN << f }
[
  File.join('test', 'bin')
].each { |f| CLOBBER << f }

file TEST => LIBRARY do |t, args|
  puts "[file] creating #{t.name}..."

  sdk_version = test_config['sdk_version']
  file_installed = File.join(libs_path(sdk_version), lib_file)

  Rake::Task['lib:install'].invoke unless FileUtils.uptodate?(file_installed, [LIBRARY])

  Dir.chdir('test') do
    Dir.mkdir('bin') unless Dir.exists?('bin')
    cmd = "#{LoomTasks.lsc(sdk_version)} #{LoomTasks.const_lib_name}Test.build"
    try(cmd, "failed to compile .loom")
  end
end

FileList[File.join('test', 'src', '**', '*.ls')].each do |src|
  file TEST => src
end


namespace :test do

  desc [
    "builds #{TEST} against #{test_config['sdk_version']} SDK",
    "the SDK is specified in test/loom.config",
    "you can change the SDK with rake set[sdk]",
    "the .loom binary is created in test/bin",
  ].join("\n")
  task :build => TEST do |t, args|
    puts "[#{t.name}] task completed, find .loom in test/bin/"
  end

  desc [
    "runs #{TEST} for CI",
    "in CI mode, the test runner will print long-form results to stdout and generate jUnit compatible reports",
    "the jUnit xml report files are written to the project root, as TEST-*.xml",
  ].join("\n")
  task :ci => TEST do |t, args|
    sdk_version = test_config['sdk_version']
    binary = t.prerequisites[0]
    main = File.join('test', LoomTasks.main_binary)

    puts "[#{t.name}] executing #{binary} as #{main}..."
    abort("could not find '#{binary}' to launch") unless File.exists?(binary)

    # loomexec expects to find bin/Main.loom, so we make a launchable copy there
    FileUtils.cp(binary, main)

    Dir.chdir('test') do
      opts = '--format junit --format console'
      cmd = LoomTasks.loomexec(sdk_version, opts)
      try(cmd, "tests failed")
    end
  end

  desc [
    "runs #{TEST} for the console",
    "the test runner will print short-form results to stdout",
  ].join("\n")
  task :run, [:seed] => TEST do |t, args|
    sdk_version = test_config['sdk_version']
    binary = t.prerequisites[0]
    main = File.join('test', LoomTasks.main_binary)

    puts "[#{t.name}] executing #{binary} as #{main}..."
    abort("could not find '#{binary}' to launch") unless File.exists?(binary)

    # loomexec expects to find bin/Main.loom, so we make a launchable copy there
    FileUtils.cp(binary, main)

    Dir.chdir('test') do
      opts = '--format ansi'
      cmd = LoomTasks.loomexec(sdk_version, opts)
      cmd = "#{cmd} --seed #{args.seed}" if args.seed
      try(cmd, "tests failed")
    end
  end

  desc [
    "sets the provided SDK version into #{test_config_file}",
    "this updates #{test_config_file} to define which SDK will compile the test apps",
    "available sdks can be listed with 'rake list_sdks'",
  ].join("\n")
  task :sdk, [:id] do |t, args|
    args.with_defaults(:id => default_sdk)
    sdk_version = args.id
    lib_dir = LoomTasks.libs_path(sdk_version)

    LoomTasks.fail("no sdk named '#{sdk_version}' found in #{sdk_root}") unless (Dir.exists?(lib_dir))

    test_config['sdk_version'] = sdk_version
    write_test_config(test_config)

    puts "[#{t.name}] task completed, sdk updated to #{sdk_version}"
  end

end

desc [
  "shorthand for rake test:run",
].join("\n")
task :test => 'test:run'
