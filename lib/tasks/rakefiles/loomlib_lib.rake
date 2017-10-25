
require 'fileutils'

require File.join(File.dirname(__FILE__), 'support')
include LoomTasks


@lib_loom_config = nil
@lib_build_config = nil

def lib_build_file()
  File.join('lib', 'src', "#{lib_name}.build")
end

def lib_config_file()
  File.join('lib', 'loom.config')
end

def lib_file()
  "#{lib_name}.loomlib"
end

def lib_name()
  LoomTasks.const_lib_name
end

def lib_version_file()
  LoomTasks.const_lib_version_file
end

def lib_config()
  @lib_loom_config || (@lib_loom_config = LoomTasks.parse_loom_config(lib_config_file))
end

def lib_build_config()
  @lib_build_config || (@lib_build_config = LoomTasks.parse_loom_config(lib_build_file))
end

def release_dir()
  'releases'
end

def readme_file()
  'README.md'
end

def write_lib_config(config)
  LoomTasks.write_loom_config(lib_config_file, config)
end

def write_lib_build_config(config)
  LoomTasks.write_loom_config(lib_build_file, config)
end

def update_lib_version(new_value)
  old_value = LoomTasks.lib_version(lib_version_file) # force the check for an existing version
  IO.write(
    lib_version_file,
    File.open(lib_version_file, 'r') { |f| f.read.gsub!(LoomTasks.lib_version_regex, '\1\2'+new_value+'\4') }
  )
end

# LIBRARY const defined at top level in loomlib.rake

[
  File.join('lib', 'build', '**'),
].each { |f| CLEAN << f }
[
  File.join('lib', 'build'),
].each { |f| CLOBBER << f }

file LIBRARY do |t, args|
  puts "[file] creating #{t.name}..."

  sdk_version = lib_config['sdk_version']

  Dir.chdir('lib') do
    Dir.mkdir('build') unless Dir.exists?('build')
    cmd = "#{LoomTasks.lsc(sdk_version)} #{lib_name}.build"
    try(cmd, "failed to compile .loomlib")
  end
end

FileList[
  File.join('lib', 'loom.config'),
  File.join('lib', 'src', '*.build'),
  File.join('lib', 'src', '**', '*.ls'),
].each do |src|
  file LIBRARY => [src]
end


desc [
  "reports loomlib version",
].join("\n")
task :version do |t, args|
  puts "#{lib_name} v#{LoomTasks.lib_version(lib_version_file)}"
end

namespace :lib do

  desc [
    "builds #{lib_file} for #{lib_config['sdk_version']} SDK",
    "the SDK is specified in test/loom.config",
    "you can change the SDK with rake set[sdk]",
    "the .loomlib binary is created in lib/build",
  ].join("\n")
  task :build => [LIBRARY] do |t, args|
    puts "[#{t.name}] task completed, find .loomlib in lib/build/"
  end

  desc [
    "prepares sdk-specific #{lib_file} for release, and updates version in README",
    "the version value will be read from #{LIB_VERSION_FILE}",
    "it must match this regex: #{lib_version_regex}",
  ].join("\n")
  task :release => [LIBRARY, 'docs'] do |t, args|
    sdk = lib_config['sdk_version']
    ext = '.loomlib'
    lib = t.prerequisites[0]
    lib_version = LoomTasks.lib_version(lib_version_file)

    if File.exists?(readme_file)
      puts "[#{t.name}] updating README to reference version #{lib_version} and sdk '#{sdk}'"
      LoomTasks.update_readme_version(readme_file, lib_version, sdk)
    else
      puts "[#{t.name}] skipped updating README (none found)"
    end

    Dir.mkdir(release_dir) unless Dir.exists?(release_dir)

    lib_release = %Q[#{File.basename(lib, ext)}-#{sdk}#{ext}]
    FileUtils.copy(lib, "#{release_dir}/#{lib_release}")

    puts "[#{t.name}] task completed, find #{lib_release} in #{release_dir}/"
  end

  desc [
    "sets the provided SDK version into #{lib_config_file}",
    "this updates #{lib_config_file} to define which SDK will compile the loomlib and be the install target",
    "available sdks can be listed with 'rake list_sdks'",
  ].join("\n")
  task :sdk, [:id] => ['lib:uninstall'] do |t, args|
    args.with_defaults(:id => default_sdk)
    sdk_version = args.id
    lib_dir = LoomTasks.libs_path(sdk_version)

    LoomTasks.fail("no sdk named '#{sdk_version}' found in #{sdk_root}") unless (Dir.exists?(lib_dir))

    lib_config['sdk_version'] = sdk_version
    write_lib_config(lib_config)

    puts "[#{t.name}] task completed, sdk updated to #{sdk_version}"
  end

  desc [
    "sets the library version number into #{lib_build_file} and #{lib_version_file}",
    "#{lib_version_file} is expected to have a line matching:",
    "#{lib_version_regex.to_s}",
  ].join("\n")
  task :version, [:v] do |t, args|
    args.with_defaults(:v => '1.0.0')
    lib_version = args.v

    lib_build_config['version'] = lib_version
    lib_build_config['modules'].first['version'] = lib_version

    write_lib_build_config(lib_build_config)
    update_lib_version(lib_version)

    puts "[#{t.name}] task completed, lib version updated to #{lib_version}"
  end

  desc [
    "installs #{lib_file} into #{lib_config['sdk_version']} SDK",
    "this makes it available to reference in .build files of any project targeting #{lib_config['sdk_version']}",
  ].join("\n")
  task :install => [LIBRARY] do |t, args|
    sdk_version = lib_config['sdk_version']
    lib = t.prerequisites[0]

    FileUtils.cp(lib, LoomTasks.libs_path(sdk_version))

    puts "[#{t.name}] task completed, #{lib_file} installed for #{sdk_version}"
  end

  desc [
    "removes #{lib_file} from #{lib_config['sdk_version']} SDK",
  ].join("\n")
  task :uninstall do |t, args|
    sdk_version = lib_config['sdk_version']
    installed_lib = File.join(LoomTasks.libs_path(sdk_version), lib_file)

    if (File.exists?(installed_lib))
      FileUtils.rm_r(installed_lib)
      puts "[#{t.name}] task completed, #{lib_file} removed from #{sdk_version}"
    else
      puts "[#{t.name}] nothing to do; no #{lib_file} found in #{sdk_version} sdk"
    end
  end

  desc [
    "lists libs installed for #{lib_config['sdk_version']} SDK",
    "the SDK is specified in test/loom.config",
    "you can change the SDK with rake set[sdk]",
  ].join("\n")
  task :show do |t, args|
    sdk_version = lib_config['sdk_version']
    lib_dir = LoomTasks.libs_path(sdk_version)

    puts("installed libs in #{lib_dir}")
    Dir.glob(File.join(lib_dir, '*')).each { |f| puts(File.basename(f)) }
  end

end
