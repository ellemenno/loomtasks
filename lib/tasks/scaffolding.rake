require 'fileutils'
require 'json'
require 'pathname'


def global_config_file
  File.join(Dir.home, '.loom', 'loom.config')
end

def default_loom_sdk
  JSON.parse(File.read(global_config_file))["default_sdk"]
end

def lib_name()
  Pathname.new(Dir.pwd).basename.to_s
end

def gitignore_pathname()
  File.join(Dir.pwd, '.gitignore')
end

def gitignore_contents()
  [
    "bin/",
    "lib/build/",
    "logs/",
    "releases/",
    "test/bin/",
    "TEST-*.xml",
    "",
  ].join("\n")
end

def lib_testapp_pathname()
  File.join(Dir.pwd, 'test', 'src', 'app', "#{lib_name}Test.ls")
end

def lib_testapp_contents()
  [
    "package",
    "{",
    "",
    "    import system.application.ConsoleApplication;",
    "",
    "    import pixeldroid.bdd.Spec;",
    "    import pixeldroid.bdd.Reporter;",
    "    import pixeldroid.bdd.reporters.AnsiReporter;",
    "    import pixeldroid.bdd.reporters.ConsoleReporter;",
    "    import pixeldroid.bdd.reporters.JunitReporter;",
    "",
    "    import #{lib_name}Spec;",
    "",
    "",
    "    public class #{lib_name}Test extends ConsoleApplication",
    "    {",
    "        override public function run():void",
    "        {",
    "            #{lib_name}Spec.describe();",
    "            addReporters();",
    "            Spec.execute();",
    "        }",
    "",
    "        private function addReporters():void",
    "        {",
    "            var arg:String;",
    "            for (var i = 0; i < CommandLine.getArgCount(); i++)",
    "            {",
    "                arg = CommandLine.getArg(i);",
    "                if (arg == '--format') Spec.addReporter(reporterByName(CommandLine.getArg(++i)));",
    "            }",
    "",
    "            if (Spec.numReporters == 0) Spec.addReporter(new ConsoleReporter());",
    "        }",
    "",
    "        private function reporterByName(name:String):Reporter",
    "        {",
    "            var r:Reporter;",
    "",
    "            switch (name.toLowerCase())",
    "            {",
    "                case 'ansi': r = new AnsiReporter(); break;",
    "                case 'console': r = new ConsoleReporter(); break;",
    "                case 'junit': r = new JunitReporter(); break;",
    "            }",
    "",
    "            return r;",
    "        }",
    "    }",
    "}",
    "",
  ].join("\n")
end

def lib_testspec_pathname()
  File.join(Dir.pwd, 'test', 'src', 'spec', "#{lib_name}Spec.ls")
end

def lib_testspec_contents()
  [
    "package",
    "{",
    "    import pixeldroid.bdd.Spec;",
    "    import pixeldroid.bdd.Thing;",
    "",
    "    import foo.#{lib_name};",
    "",
    "    public static class #{lib_name}Spec",
    "    {",
    "        public static function describe():void",
    "        {",
    "            var it:Thing = Spec.describe('#{lib_name}');",
    "",
    "            it.should('have useful tests', function() {",
    "                it.expects(true).toBeFalsey();",
    "            });",
    "        }",
    "    }",
    "}",
    "",
  ].join("\n")
end

def loombuild_pathname(dir)
  name = (dir == 'test') ? "#{lib_name}Test.build" : "#{lib_name}.build"
  File.join(Dir.pwd, dir, 'src', name)
end

def loombuild_contents(dir)
  is_test = (dir == 'test')

  name = is_test ? "#{lib_name}Test" : lib_name
  dir = is_test ? 'bin' : 'build'
  ref = is_test ? [ 'System', 'Spec', lib_name ] : [ 'System' ]
  src = is_test ? [ 'app', 'spec' ] : [ '.' ]

  obj = {
    :name => name,
    :version => '1.0',
    :outputDir => dir,
    :references => ref,
    :modules => [
      {
        :name => name,
        :version => '1.0',
        :sourcePath => src,
      },
    ],
  }
  obj[:executable] = true if is_test

  [
    JSON.pretty_generate(obj),
    "",
  ].join("\n")
end

def loomconfig_pathname(dir)
  File.join(Dir.pwd, dir, 'loom.config')
end

def loomconfig_contents()
  [
    JSON.pretty_generate({ :sdk_version => default_loom_sdk() }),
    "",
  ].join("\n")
end

def rakefile_pathname()
  File.join(Dir.pwd, 'Rakefile')
end

def rakefile_contents()
  [
    "LIB_NAME = '#{lib_name}'",
    "LIB_VERSION_FILE = File.join('lib', 'src', '#{lib_name}.ls')",
    "",
    "load(File.join(ENV['HOME'], '.loom', 'tasks', 'loomlib.rake'))",
    "#load(File.join(ENV['HOME'], '.loom', 'tasks', 'loomlib_demo.rake')) # optional",
    "",
  ].join("\n")
end

def sourcefile_pathname()
  File.join(Dir.pwd, 'lib', 'src', "#{lib_name}.ls")
end

def sourcefile_contents()
  [
    "package foo",
    "{",
    "",
    "    public class #{lib_name}",
    "    {",
    "        public static const version:String = '1.0.0';",
    "    }",
    "}",
    "",
  ].join("\n")
end


task :default => :usage

task :usage do |t, args|
  puts ''
  puts "#{File.basename($0)}: a utility to create a new loomlib directory structure"
  puts ''
  puts 'typically this is run from another directory, to bootstrap a new loomlib project there:'
  puts 'cd MyLoomlib'
  puts "rake -f #{File.join(Dir.home, '.loom', 'tasks', File.basename($0))} new:loomlib"
  puts 'rake'
end

namespace :new do

  task :gitignore do |t, args|
    File.open(gitignore_pathname, 'w') { |f| f.write(gitignore_contents) }
  end

  task :rakefile do |t, args|
    File.open(rakefile_pathname, 'w') { |f| f.write(rakefile_contents) }
  end

  task :libdir do |t, args|
    pathname = loomconfig_pathname('lib')
    FileUtils.mkdir_p(File.dirname(pathname))
    File.open(pathname, 'w') { |f| f.write(loomconfig_contents) }

    pathname = loombuild_pathname('lib')
    FileUtils.mkdir_p(File.dirname(pathname))
    File.open(pathname, 'w') { |f| f.write(loombuild_contents('lib')) }

    pathname = sourcefile_pathname()
    FileUtils.mkdir_p(File.dirname(pathname))
    File.open(pathname, 'w') { |f| f.write(sourcefile_contents()) }
  end

  task :testdir do |t, args|
    pathname = loomconfig_pathname('test')
    FileUtils.mkdir_p(File.dirname(pathname))
    File.open(pathname, 'w') { |f| f.write(loomconfig_contents) }

    pathname = loombuild_pathname('test')
    FileUtils.mkdir_p(File.dirname(pathname))
    File.open(pathname, 'w') { |f| f.write(loombuild_contents('test')) }

    pathname = lib_testapp_pathname()
    FileUtils.mkdir_p(File.dirname(pathname))
    File.open(pathname, 'w') { |f| f.write(lib_testapp_contents()) }

    pathname = lib_testspec_pathname()
    FileUtils.mkdir_p(File.dirname(pathname))
    File.open(pathname, 'w') { |f| f.write(lib_testspec_contents()) }
  end

  desc [
    "scaffolds the directories and files for a new loomlib project",
    "creates a .gitignore file, rakefile, and template library and test code"
    "this code assumes (but does not enforce) being run in an empty directory"
  ].join("\n")
  task :loomlib => [:gitignore, :rakefile, :libdir, :testdir]

end
