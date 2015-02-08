
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# loomlib.rake - common Rake tasks for loomlib projects
#
# usage
#   add the following to your project's Rakefile:
#
#   load(File.join(ENV['HOME'], '.loom', 'tasks', 'loomlib.rake'))

require 'etc'
require 'fileutils'
require 'json'
require 'rake/clean'

require File.join(File.dirname(__FILE__), 'support')
include LoomTasks


def const_find(name)
  Module.const_defined?(name) ? Module.const_get(name) : nil
end

def const_lib_name
  const_find('LIB_NAME')
end

def const_lib_version_file
  const_find('LIB_VERSION_FILE')
end

def lib_config_file()
  File.join('lib', 'loom.config')
end

def lib_version_file()
  const_lib_version_file
end

def readme_file()
  File.join('README.md')
end

def test_config_file()
  File.join('test', 'loom.config')
end

def lib_config()
  @lib_loom_config || (@lib_loom_config = parse_loom_config(lib_config_file))
end

def test_config()
  @test_loom_config || (@test_loom_config = parse_loom_config(test_config_file))
end

def write_lib_config(config)
  write_loom_config(lib_config_file, config)
end

def write_test_config(config)
  write_loom_config(test_config_file, config)
end


@lib_loom_config = nil
@test_loom_config = nil

CLEAN.include ['lib/build/**', 'test/bin/**']
CLOBBER.include ['lib/build', 'test/bin', 'releases']
Rake::Task[:clobber].enhance ['lib:uninstall']


task :default => :list_targets

task :list_targets => :check_consts do |t, args|
  a = "#{const_lib_name} v#{lib_version} Rakefile"
  b = "running on Ruby #{RUBY_VERSION}"
  c = "lib=#{lib_config['sdk_version']}"
  d = "test=#{test_config['sdk_version']}"
  puts "#{a} #{b} (#{c}, #{d})"
  system("rake -T")
  puts "(using #{File.basename(__FILE__)} v#{LoomTasks::VERSION})"
  puts ''
end

task :check_consts do |t, args|
  fail("please define the LIB_NAME constant before loading #{File.basename(__FILE__)}") unless const_lib_name
  fail("please define the LIB_VERSION_FILE constant before loading #{File.basename(__FILE__)}") unless const_lib_version_file
end


LIBRARY = "lib/build/#{const_lib_name}.loomlib"

FileList['lib/src/**/*.ls'].each do |src|
  file LIBRARY => src
end

file LIBRARY do |t, args|
  puts "[file] creating #{t.name}..."

  sdk_version = lib_config['sdk_version']

  Dir.chdir('lib') do
    Dir.mkdir('build') unless Dir.exists?('build')
    cmd = "#{lsc(sdk_version)} #{const_lib_name}.build"
    try(cmd, "failed to compile .loomlib")
  end

  puts ''
end


APP = "test/bin/#{const_lib_name}Test.loom"

FileList['test/src/app/*.ls'].each do |src|
  file APP => src
end

FileList['test/src/spec/*.ls'].each do |src|
  file APP => src
end

file APP => LIBRARY do |t, args|
  puts "[file] creating #{t.name}..."

  sdk_version = test_config['sdk_version']
  file_installed = "#{sdk_root}/#{sdk_version}/libs/#{const_lib_name}.loomlib"

  Rake::Task['lib:install'].invoke unless FileUtils.uptodate?(file_installed, [LIBRARY])

  Dir.chdir('test') do
    Dir.mkdir('bin') unless Dir.exists?('bin')
    cmd = "#{lsc(sdk_version)} #{const_lib_name}Test.build"
    try(cmd, "failed to compile .loom")
  end

  puts ''
end


desc "sets the provided SDK version into lib/loom.config and test/loom.config"
task :set, [:sdk] => 'lib:uninstall' do |t, args|
  args.with_defaults(:sdk => 'sprint33')
  sdk_version = args.sdk

  lib_config['sdk_version'] = sdk_version
  test_config['sdk_version'] = sdk_version

  write_lib_config(lib_config)
  write_test_config(test_config)

  puts "[#{t.name}] task completed, sdk updated to #{sdk_version}"
  puts ''
end

namespace :lib do

  desc "builds #{const_lib_name}.loomlib for the SDK specified in lib/loom.config"
  task :build => LIBRARY do |t, args|
    puts "[#{t.name}] task completed, find .loomlib in lib/build/"
    puts ''
  end

  desc "prepares sdk-specific #{const_lib_name}.loomlib for release"
  task :release => LIBRARY do |t, args|
    lib = "lib/build/#{const_lib_name}.loomlib"
    sdk = lib_config['sdk_version']
    ext = '.loomlib'
    release_dir = 'releases'

    puts "[#{t.name}] updating README to reference version #{lib_version}"
    update_readme_version()

    Dir.mkdir(release_dir) unless Dir.exists?(release_dir)

    lib_release = %Q[#{File.basename(lib, ext)}-#{sdk}#{ext}]
    FileUtils.copy(lib, "#{release_dir}/#{lib_release}")

    puts "[#{t.name}] task completed, find #{lib_release} in #{release_dir}/"
    puts ''
  end

  desc "installs #{const_lib_name}.loomlib into the SDK specified in lib/loom.config"
  task :install => LIBRARY do |t, args|
    lib = "lib/build/#{const_lib_name}.loomlib"
    sdk_version = lib_config['sdk_version']
    libs_path = "#{sdk_root}/#{sdk_version}/libs"

    cmd = "cp #{lib} #{libs_path}"
    try(cmd, "failed to install lib")

    puts "[#{t.name}] task completed, #{const_lib_name}.loomlib installed for #{sdk_version}"
    puts ''
  end

  desc "removes #{const_lib_name}.loomlib from the SDK specified in lib/loom.config"
  task :uninstall do |t, args|
    sdk_version = lib_config['sdk_version']
    lib = "#{sdk_root}/#{sdk_version}/libs/#{const_lib_name}.loomlib"

    if (File.exists?(lib))
      cmd = "rm -f #{lib}"
      try(cmd, "failed to remove lib")
      puts "[#{t.name}] task completed, #{const_lib_name}.loomlib removed from #{sdk_version}"
    else
      puts "[#{t.name}] nothing to do;  no #{const_lib_name}.loomlib found in #{sdk_version} sdk"
    end
    puts ''
  end

  desc "lists libs installed for the SDK specified in lib/loom.config"
  task :show do |t, args|
    sdk_version = lib_config['sdk_version']

    cmd = "ls -1 #{sdk_root}/#{sdk_version}/libs"
    try(cmd, "failed to list contents of #{sdk_version} libs directory")

    puts ''
  end

end

namespace :test do

  desc "builds #{const_lib_name}Test.loom with the SDK specified in test/loom.config"
  task :build => APP do |t, args|
    puts "[#{t.name}] task completed, find .loom in test/bin/"
    puts ''
  end

  desc "runs #{const_lib_name}Test.loom"
  task :run => APP do |t, args|
    puts "[#{t.name}] running #{t.prerequisites[0]}..."

    sdk_version = test_config['sdk_version']
    cmd = "#{loomexec(sdk_version)} test/bin/#{const_lib_name}Test.loom --format ansi"
    try(cmd, "failed to run .loom")

    puts ''
  end

  desc "runs #{const_lib_name}Test.loom for CI"
  task :ci => APP do |t, args|
    puts "[#{t.name}] running #{t.prerequisites[0]}..."

    sdk_version = test_config['sdk_version']
    cmd = "#{loomexec(sdk_version)} test/bin/#{const_lib_name}Test.loom --format junit --format console"
    try(cmd, "failed to run .loom")

    puts ''
  end

end
