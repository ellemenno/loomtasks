loom tasks
==========

Rake tasks for working with loomlibs

- [overview](#overview)
- [installation](#installation)
- [usage](#usage)
- [conventions](#conventions)
- [contributing](#contributing)

<br>

## overview

loomlibs are linkable LoomScript code libraries used to expand features of the [Loom SDK][loomsdk].

If you use [Rake][rake] and follow a consistent file layout across projects, these tasks can simplify the steps of seting up, building, installing, testing, demo-ing, and releasing loom libraries (`*.loomlib`).

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
0. Run `test` to see the auto-created library be built, the test harness run, and the first test fail:
    * `rake test`
0. Add your code and tests (in `lib/src/`, and `test/src/`)

### more details

Running `rake` in your project directory will execute the default task, which prints the list of available tasks and a short description of what they do:

    Foo v1.2.3 Rakefile running on Ruby 2.3.0
    rake clean             # removes intermediate files to ensure a clean build
    rake cli[options]      # shorthand for rake cli:run
    rake cli:build         # builds cli/bin/FooDemoCLI.loom for sprint34 SDK
    rake cli:run[options]  # executes cli/bin/FooDemoCLI.loom as a commandline app, with options, if provided
    rake cli:sdk[id]       # sets the provided SDK version into cli/loom.config
    rake clobber           # removes all generated artifacts to restore project to checkout-like state
    rake gui               # shorthand for rake gui:run
    rake gui:build         # builds gui/bin/FooDemoGUI.loom for sprint34 SDK
    rake gui:run           # launches gui/bin/FooDemoGUI.loom as a GUI app
    rake gui:sdk[id]       # sets the provided SDK version into gui/loom.config
    rake help              # show detailed usage and project info
    rake lib:build         # builds Foo.loomlib for sprint34 SDK
    rake lib:install       # installs Foo.loomlib into sprint34 SDK
    rake lib:release       # prepares sdk-specific Foo.loomlib for release, and updates version in README
    rake lib:sdk[id]       # sets the provided SDK version into lib/loom.config
    rake lib:show          # lists libs installed for sprint34 SDK
    rake lib:uninstall     # removes Foo.loomlib from sprint34 SDK
    rake lib:version[v]    # sets the library version number into lib/src/Foo.build and lib/src/Foo.ls
    rake sdk[id]           # sets the provided SDK version in the config files of lib, cli, gui, and test
    rake test              # shorthand for rake test:run
    rake test:build        # builds test/bin/FooTest.loom against sprint34 SDK
    rake test:ci           # runs test/bin/FooTest.loom for CI
    rake test:run          # runs test/bin/FooTest.loom for the console
    rake test:sdk[id]      # sets the provided SDK version into test/loom.config
    rake version           # reports loomlib version
    (using loomtasks v3.0.2)

If you are looking for more detail on any of the tasks, use `rake help`.

The Rake tasks are defined with dependencies and modification triggers, so you can just run `rake test` every time you edit a source file, and the library and test app will be rebuilt as needed automatically.

## conventions

The loomlib rake tasks make the following assumptions about the layout of a project.

> If there are portions of the scaffold that you are not interested in using (i.e. `cli`, `gui`), just delete those folders, and the corresponding rake tasks will not be loaded.

### directory structure

    foo-loomlib $
    ├─cli/
    ├─gui/
    ├─lib/
    ├─Rakefile
    └─test/

* library source is under `lib/`
* source for a CLI demo is under `cli/`; the CLI demo app will consume the library and illustrate its use from the command line
* source for a GUI demo is under `gui/`; the GUI demo app will consume the library and illustrate its use via a graphical user interface
* the project uses a `Rakefile` for building, testing, and preparing releases
* library test source is under `test/`; the test app will consume the library and exercise it
* [spec-ls][spec-ls] is the testing framework

#### demos

Support for CLI demo tasks comes from [`loomlib_cli.rake`](lib/tasks/rakefiles/loomlib_cli.rake).

`cli/` contains a command line demonstration app. <br>

    └─cli
      ├─bin
      │ └─Main.loom
      ├─loom.config
      └─src
        ├─FooDemoCLI.ls
        └─FooDemoCLI.build

* the cli demo application is built into, and executed from `cli/bin/`
* the cli demo has its own loom config file at `cli/loom.config`
* the cli demo has its own loom build file at `cli/src/FooDemoCLI.build`
* the cli demo source code is under `cli/src/`

Support for GUI demo tasks comes from [`loomlib_gui.rake`](lib/tasks/rakefiles/loomlib_gui.rake).

`gui/` contains a functional graphical demonstration app. <br>

    └─gui
      ├─assets
      ├─bin
      │ └─Main.loom
      ├─loom.config
      └─src
        ├─FooDemoGUI.ls
        └─FooDemoGUI.build

* the gui demo assets are under `gui/assets/`
* the gui demo application is built into, and run from `gui/bin/`
* the gui demo has its own loom config file at `gui/loom.config`
* the gui demo has its own loom build file at `gui/src/FooDemoGUI.build`
* the gui demo source code is under `gui/src/`

#### lib

Support for library tasks comes from [`loomlib_lib.rake`](lib/tasks/rakefiles/loomlib_lib.rake).

`lib/` contains the library code, which will be packaged into a `.loomlib` file for installation into a Loom SDK. <br>

    ├─lib
    │ ├─build
    │ │ └─Foo.loomlib
    │ ├─loom.config
    │ └─src
    │   ├─Foo.build
    │   └─com
    │     └─bar
    │       └─Foo.ls

* the loomlib is built into `lib/build/`
* the library has its own loom config file at `lib/loom.config`
* the library has its own loom build file at `lib/src/Foo.build`
* library source code is under `lib/src/`

##### version

Some file under `lib/` contains the following line (where `1.2.3` is the version of your library):

```ls
public static const version:String = '1.2.3';
```

This provides runtime access to the library version, and is also used in the name of the loomlib built for release (compatible with a corresponding [GitHub release][gh-releases]).

#### test

Support for test tasks comes from [`loomlib_test.rake`](lib/tasks/rakefiles/loomlib_test.rake).
Use of [spec-ls][spec-ls] is assumed.

`test/` contains unit tests of the library code. The tests are not packaged with the loomlib; they are run from a separate test runner app. <br>

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

* the test application is built into, and run from `test/bin/`
* the tests have their own loom config file at `test/loom.config`
* the tests have their own loom build file at `test/src/FooTest.build`
* the test application source code is under `test/src/app/`
* the specification source code is under `test/src/spec/`


## contributing

Pull requests are welcome!


[gh-releases]: https://help.github.com/articles/about-releases/ "about GitHub releases"
[loomcli]: https://loomsdk.com/#see "See the Loom CLI demo"
[loomsdk]: https://github.com/LoomSDK/LoomSDK "The Loom SDK, a native mobile app and game framework"
[rake]: https://rubygems.org/gems/rake "Rake (Ruby make)"
[spec-ls]: https://github.com/pixeldroid/spec-ls "spec-ls: a simple specification framework for loom"
