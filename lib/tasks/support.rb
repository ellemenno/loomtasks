
module LoomTasks

  VERSION = '1.0.1'

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

  def sdk_root()
    File.join(Dir.home, '.loom', 'sdks')
  end

  def try(cmd, failure_message)
    fail(failure_message) if (exec_with_echo(cmd) != EXIT_OK)
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
    File.open(lib_version_file, 'r') { |f| f.read.scan(lib_version_regex).first[0] }
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

end
