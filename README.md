loom tasks
==========

Rake tasks for working with loomlibs


## overview

If you use [Rake][rake] and follow a consistent file layout across projects, these tasks can provide help for building, testing, releasing and installing loom libraries (`*.loomlib`).

The tasks install into your `.loom` directory, and can be loaded from there into the Rakefiles of your projects.
They are no substitute for something like Gem or Bundler for Ruby, but they're a first step in that direction.

loom tasks do not replace or interfere with the [loomcli][loomcli]; the two can be used safely together.


## conventions

The loomlib rake tasks make the following assumptions about the layout of a project:

### directory structure

    foo-loomlib $
    ├─lib/
    ├─Rakefile
    └─test/

* library source will go under `lib/`
* the project will use a `Rakefile` for building, testing, and preparing releases
* library test source will go under `test/`; the test app will consume the library and exercise it

#### lib

    ├─lib
    │ ├─assets
    │ ├─bin
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

    public static const version:String = '1.2.3';

This is used to name the loomlib that gets compiled (and anticipates a corresponding [GitHub release][gh-releases]).

#### test

    └─test
      ├─assets
      ├─bin
      │ └─FooTest.loom
      ├─loom.config
      └─src
        ├─app
        │ └─FooTest.ls
        ├─spec
        │ └─FooSpec.ls
        └─FooTest.build

* the test application wil be built into `test/bin/`
* the tests have their own loom config file at `test/loom.config`
* the tests have their own loom build file at `test/src/Foo.build`
* the test application source code is under `test/src/app/`
* the specification source code is under `test/src/spec/`


## installation

Clone this repo.

0. Run `rake install` to:
    * create a `tasks` folder in your Loom SDK home directory (`~/.loom`)
    * install the Rake tasks from this project into it.
0. Run `rake uninstall` to:
    * delete the `tasks` folder.
    * _**Note:** this deletes the whole folder! So be careful if you decide to put your own tasks in there._


## usage

In your project's `Rakefile`, declare the name of your library and path to the file containing version info.

    LIB_NAME = 'Foo'
    LIB_VERSION_FILE = File.join('lib', 'src', 'com', 'bar', 'Foo.ls')

Then load the tasks:

    load(File.join(ENV['HOME'], '.loom', 'tasks', 'loomlib.rake'))

> Note: your whole Rakefile may be just those three lines if there isn't anything else you need to do

Now run `rake` to execute the default task, which will print the list of available tasks and some useful info:

    Foo v1.2.3 Rakefile running on Ruby 2.1.1 (lib=sprint33, test=sprint33)
    rake clean          # Remove any temporary products
    rake clobber        # Remove any generated file
    rake lib:build      # builds Foo.loomlib for the SDK specified in lib/loom.config
    rake lib:install    # installs Foo.loomlib into the SDK specified in lib/loom.config
    rake lib:release    # prepares sdk-specific Foo.loomlib for release
    rake lib:show       # lists libs installed for the SDK specified in lib/loom.config
    rake lib:uninstall  # removes Foo.loomlib from the SDK specified in lib/loom.config
    rake set[sdk]       # sets the provided SDK version into lib/loom.config and test/loom.config
    rake test:build     # builds FooTest.loom with the SDK specified in test/loom.config
    rake test:ci        # runs FooTest.loom for CI
    rake test:run       # runs FooTest.loom
    (using loomlib.rake v1.0.0)

The Rake tasks are defined with dependencies and modification triggers, so you can just run `rake test:run` every time you edit a source file, and the library and test app will be rebuilt as needed automatically.


## contributing

Pull requests are welcome!


[rake]: https://rubygems.org/gems/rake "Rake (Ruby make)"
[loomcli]: https://loomsdk.com/#see "See the Loom CLI demo"
[gh-releases]: https://help.github.com/articles/about-releases/ "about GitHub releases"
