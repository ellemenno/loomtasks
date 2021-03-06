# encoding: utf-8

require 'json'
require 'rbconfig'
require 'yaml'

module LoomTasks

  VERSION = '3.3.0'

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
    LoomTasks.fail(failure_message) if (exec_with_echo(cmd) != EXIT_OK)
  end

  def path_to_exe(cmd)
    # from https://stackoverflow.com/a/5471032
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']

    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each do |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable?(exe) && !File.directory?(exe)
      end
    end

    return nil
  end

  def bin_dir()
    'bin'
  end

  def main_binary()
    File.join(bin_dir, 'Main.loom')
  end

  def loomexec(sdk_version, args = nil)
    # needs to be run in the project root
    # stubbornly, the runner loads bin/Main.loom from the current working directory
    # weirdly, the runner expects a throw-away arg, so we pass an ignorable something
    ignorable = '//'
    executable = File.join(sdk_tools(sdk_version), 'loomexec')

    args ? "#{executable} #{ignorable} #{args}" : executable
  end

  def loomlaunch(sdk_version)
    # needs to be run in the project root
    # magically, the launcher loads bin/Main.loom from the current working directory
    return loomlaunch_osx(sdk_version) if osx?
    return loomlaunch_win(sdk_version) if windows?
  end

  def loomlaunch_win(sdk_version)
    exe = File.join(sdk_bin(sdk_version), 'LoomPlayer.exe')
    %(start "Loom" #{exe} ProcessID #{Process.pid})
  end

  def loomlaunch_osx(sdk_version)
    File.join(sdk_bin(sdk_version), 'LoomPlayer.app', 'Contents', 'MacOS', 'LoomPlayer')
  end

  def lsc(sdk_version)
    # needs to be run in the project root
    File.join(sdk_tools(sdk_version), 'lsc')
  end

  def global_config_file()
    File.join(Dir.home, '.loom', 'loom.config')
  end

  def sdk_root(sdk_version = nil)
    root = File.join(Dir.home, '.loom', 'sdks')
    sdk_version ? File.join(root, sdk_version) : root
  end

  def sdk_architecture()
    os = 'unknown'
    arch = 'x86'

    if osx?
      os = "osx"
      arch = "x64" if (`uname -m`.chomp == 'x86_64')
    elsif windows?
      os = "windows"
      arch = "x64" if (/\.*64.*/ =~ `reg query "HKLM\\System\\CurrentControlSet\\Control\\Session Manager\\Environment" /v PROCESSOR_ARCHITECTURE`)
    elsif linux?
      os = "linux"
      arch = "x64" if (`uname -m`.chomp == 'x86_64')
    end

    "#{os}-#{arch}"
  end

  def sdk_bin(sdk_version)
    File.join(sdk_root, sdk_version, 'bin', sdk_architecture, 'bin')
  end

  def sdk_tools(sdk_version)
    File.join(sdk_root, sdk_version, 'bin', sdk_architecture, 'tools')
  end

  def parse_loom_config(file)
    JSON.parse(File.read(file))
  end

  def write_loom_config(file, config)
    IO.write(file, "#{JSON.pretty_generate(config)}\n")
  end

  def parse_yaml_config(file)
    File.file?(file) ? YAML.load(File.read(file)) : {}
  end

  def write_yaml_config(file, config)
    IO.write(file, "#{config.to_yaml}\n")
  end

  def const_find(name)
    Module.const_defined?(name) ? Module.const_get(name) : nil
  end

  def const_lib_name
    const_find('LIB_NAME')
  end

  def const_lib_version_file
    const_find('LIB_VERSION_FILE')
  end

  def lib_version_regex()
    # \1 => <space>
    # \2 => public static const version:String = '
    # \3 => <n.n.n>
    # \4 => '
    Regexp.new(%r/(^\s*)(public static const version:String = ')(\d+\.\d+\.\d+)(';)/)
  end

  def lib_version(version_file)
    File.open(version_file, 'r') do |f|
      matches = f.read.scan(lib_version_regex)
      raise("No version const defined in #{lib_version_file}") if matches.empty?
      matches.first[2]
    end
  end

  def libs_path(sdk_version)
    File.join(sdk_root, sdk_version, 'libs')
  end

  def installation_path_regex()
    # \1 => .loom/sdks/
    # \2 => <sdk>
    # \3 => /libs/<lib_name>.loomlib
    Regexp.new(%r/(\.loom\/sdks\/)(.*)(\/libs\/.*\.loomlib)/)
  end

  def download_url_regex()
    # \1 => download/v
    # \2 => <n.n.n>
    # \3 => /<lib_name>-
    # \4 => <sdk>
    # \5 => .loomlib
    Regexp.new(%r/(download\/v)(\d+\.\d+\.\d+)(\/.*-)(.*)(.loomlib)/)
  end

  def update_readme_version(readme_file, new_value, sdk_version)
    IO.write(
      readme_file,
      File.open(readme_file, 'r') do |f|
        f.read
        .gsub(download_url_regex(), '\1'+new_value+'\3'+sdk_version+'\5')
        .gsub(installation_path_regex(), '\1'+sdk_version+'\3')
      end
    )
  end

  def windows?
    return true if RbConfig::CONFIG['host_os'] =~ /mingw|mswin/
    false
  end

  def osx?
    return true if RbConfig::CONFIG['host_os'] =~ /darwin/
    false
  end

  def linux?
    return true if RbConfig::CONFIG['host_os'] =~ /linux/
    false
  end

end
