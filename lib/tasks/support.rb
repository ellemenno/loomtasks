# encoding: utf-8

require 'rbconfig'

module LoomTasks

  VERSION = '1.1.0'

  EXIT_OK = 0

  def exec_with_echo(cmd)
    puts(cmd)
    stdout = %x[#{cmd}]
    puts(stdout) unless stdout.empty?
    $?.exitstatus
  end

  def fail(message)
    abort("✘ #{message}")
  end

  def try(cmd, failure_message)
    fail(failure_message) if (exec_with_echo(cmd) != EXIT_OK)
  end

  def loomexec(sdk_version)
    File.join(sdk_root, sdk_version, 'tools', 'loomexec')
  end

  def loomlaunch_win(sdk_version)
    exe = File.join(sdk_root, sdk_version, 'bin', 'LoomDemo.exe')
    %(start "Loom" #{exe} ProcessID #{Process.pid})
  end

  def loomlaunch_osx(sdk_version)
    File.join(sdk_root, sdk_version, 'bin', 'LoomDemo.app', 'Contents', 'MacOS', 'LoomDemo')
  end

  def loomlaunch(sdk_version)
    # needs to be run in the project root
    # magically, the launcher loads bin/Main.loom from the current working directory
    return loomlaunch_osx(sdk_version) if osx?
    return loomlaunch_win(sdk_version) if windows?
  end

  def lsc(sdk_version)
    # needs to be run in the project root
    File.join(sdk_root, sdk_version, 'tools', 'lsc')
  end

  def sdk_root()
    File.join(Dir.home, '.loom', 'sdks')
  end

  def parse_loom_config(file)
    JSON.parse(File.read(file))
  end

  def write_loom_config(file, config)
    File.open(file, 'w') { |f| f.write(JSON.pretty_generate(config)) }
  end

  def lib_version_regex()
    Regexp.new(%q/^\s*public static const version:String = '(\d\.\d\.\d)';/)
  end

  def lib_version()
    File.open(lib_version_file, 'r') do |f|
      matches = f.read.scan(lib_version_regex)
      raise("No version const defined in #{lib_version_file}") if matches.empty?
      matches.first[0]
    end
  end

  def libs_path(sdk_version)
    File.join(sdk_root, sdk_version, 'libs')
  end

  def readme_version_regex()
    Regexp.new(%q/download\/v(\d\.\d\.\d)/)
  end

  def readme_version_literal()
    "download/v#{lib_version}"
  end

  def update_readme_version()
    IO.write(
      readme_file,
      File.open(readme_file, 'r') { |f| f.read.gsub!(readme_version_regex, readme_version_literal) }
    )
  end

  def windows?
    return false if RUBY_PLATFORM =~ /cygwin/ # i386-cygwin
    return true if ENV['OS'] == 'Windows_NT'
    false
  end

  def osx?
    return true if RUBY_PLATFORM =~ /darwin/
    false
  end

end
