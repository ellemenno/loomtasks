loom tasks
==========

Rake tasks for working with loomlibs


## overview

If you use [Rake][rake] and follow a consistent file layout across projects, these tasks can provide help for building, testing, demo-ing, releasing and installing loom libraries (`*.loomlib`).

The tasks install into your `.loom` directory, and can be loaded from there into the Rakefiles of your projects.

loom tasks do not replace or interfere with the [loomcli][loomcli]; the two can be used safely together.


## installation

Clone this repo.

0. Run `rake install` to:
    * create a `tasks` folder in your Loom SDK home directory (`~/.loom`)
    * install the Rake tasks from this project into it.
0. Run `rake uninstall` to:
    * delete the `tasks` folder.
    * _**Note:** this deletes the whole folder! So be careful if you decide to put your own tasks in there._


## usage

0. Scaffold a new project structure:
    * `rake -f ~/.loom/tasks/scaffolding.rake new:loomlib`
0. Test and see the auto-created library be built, the test harness and run, and the first test fail:
    * `rake test`
0. Add your code and tests (in `lib/src/`, and `test/src/`)

### more details

Running `rake` in your project directory will execute the default task, which prints the list of available tasks and some useful info:

    Foo v1.2.3 Rakefile running on Ruby 2.3.0 (lib=sprint34, test=sprint34)
    rake clean             # removes intermediate files to ensure a clean build
    rake cli[options]      # shorthand for rake cli:run
    rake cli:build         # builds cli/bin/FooDemoCLI.loom for sprint34 SDK
    rake cli:run[options]  # executes cli/bin/FooDemoCLI.loom as a commandline app, with options, if provided
    rake clobber           # removes all generated artifacts to restore project to checkout-like state
    rake gui               # shorthand for rake gui:run
    rake gui:build         # builds gui/bin/FooDemoGUI.loom for sprint34 SDK
    rake gui:run           # launches gui/bin/FooDemoGUI.loom as a GUI app
    rake help              # show detailed usage and project info
    rake lib:build         # builds Foo.loomlib for sprint34 SDK
    rake lib:install       # installs Foo.loomlib into sprint34 SDK
    rake lib:release       # prepares sdk-specific Foo.loomlib for release, and updates version in README
    rake lib:show          # lists libs installed for sprint34 SDK
    rake lib:uninstall     # removes Foo.loomlib from sprint34 SDK
    rake test              # shorthand for rake test:run
    rake test:build        # builds test/bin/FooTest.loom against sprint34 SDK
    rake test:ci           # runs test/bin/FooTest.loom for CI
    rake test:run          # runs test/bin/FooTest.loom for the console
    rake version           # reports loomlib version
    (using loomtasks v3.0.0)

    use `rake -D` for more detailed task descriptions

If you are looking for more detail on any of the tasks, use `rake -D`, e.g.:

```console
$ rake -D set
rake set[sdk]
    sets the provided SDK version into lib/loom.config and test/loom.config
    lib/loom.config defines which SDK will be used to compile the loomlib, and also where to install it
    test/loom.config defines which SDK will be used to compile the test app and demo app
```

The Rake tasks are defined with dependencies and modification triggers, so you can just run `rake test` every time you edit a source file, and the library and test app will be rebuilt as needed automatically.


## conventions

The loomlib rake tasks make the following assumptions about the layout of a project:

### directory structure

    foo-loomlib $
    ├─cli/
    ├─gui/
    ├─lib/
    ├─Rakefile
    └─test/

* library source will go under `lib/`
* library CLI demo source will go under `cli/`; the demo app will consume the library and illustrate its use from the command line
* library GUI demo source will go under `gui/`; the demo app will consume the library and illustrate its use via a graphical user interface
* the project will use a `Rakefile` for building, testing, and preparing releases
* library test source will go under `test/`; the test app will consume the library and exercise it
* [spec-ls][spec-ls] is the testing framework

#### demos

Support for demo tasks comes from `loomlib_demo.rake`.

`cli/` is for a functional command line demonstration app. <br>

    └─cli
      ├─assets
      ├─bin
      │ └─Main.loom
      ├─loom.config
      └─src
        ├─FooDemoCLI.ls
        └─FooDemoCLI.build

* the demo application wil be built into `cli/bin/`
* the demo has its own loom config file at `cli/loom.config`
* the demo has its own loom build file at `cli/src/FooDemoCLI.build`
* the demo source code is under `cli/src/`

`gui/` is for a functional graphical demonstration app. <br>

    └─gui
      ├─assets
      ├─bin
      │ └─Main.loom
      ├─loom.config
      └─src
        ├─FooDemoGUI.ls
        └─FooDemoGUI.build

* the demo application wil be built into `gui/bin/`
* the demo has its own loom config file at `gui/loom.config`
* the demo has its own loom build file at `gui/src/FooDemoGUI.build`
* the demo source code is under `gui/src/`

#### lib

Support for test tasks comes from `loomlib_lib.rake`.

`lib/` is for the library code, which will be packaged into a `.loomlib` file for installation into a LoomSDK. <br>

    ├─lib
    │ ├─build
    │ │ └─Foo.loomlib
    │ ├─loom.config
    │ └─src
    │   ├─Foo.build
    │   └─com
    │     └─bar
    │       └─Foo.ls

* the loomlib wil be built into `lib/build/`
* the library has its own loom config file at `lib/loom.config`
* the library has its own loom build file at `lib/src/Foo.build`
* library source code is under `lib/src/`

##### version

Some file under `lib/` must contain the following line (where `1.2.3` is the version of your library):

```ls
public static const version:String = '1.2.3';
```

This is used to name the loomlib that gets compiled (and anticipates a corresponding [GitHub release][gh-releases]).

#### test

Support for test tasks comes from `loomlib_test.rake`. Use of [spec-ls][spec-ls] is assumed.

`test/` is for unit tests of the library code. The tests are not packaged with the loomlib; they are run from a separate test runner app. <br>

    └─test
      ├─bin
      │ └─Main.loom
      ├─loom.config
      └─src
        ├─app
        │ └─FooTest.ls
        ├─spec
        │ └─FooSpec.ls
        └─FooTest.build

* the test application wil be built into `test/bin/`
* the tests have their own loom config file at `test/loom.config`
* the tests have their own loom build file at `test/src/FooTest.build`
* the test application source code is under `test/src/app/`
* the specification source code is under `test/src/spec/`


## contributing

Pull requests are welcome!


[gh-releases]: https://help.github.com/articles/about-releases/ "about GitHub releases"
[loomcli]: https://loomsdk.com/#see "See the Loom CLI demo"
[rake]: https://rubygems.org/gems/rake "Rake (Ruby make)"
[spec-ls]: https://github.com/pixeldroid/spec-ls "spec-ls: a simple specification framework for loom"
