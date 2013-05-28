# Dolt - The Git project browser

<a href="http://travis-ci.org/cjohansen/libdolt" class="travis">
  <img src="https://secure.travis-ci.org/cjohansen/libdolt.png">
</a>

Dolt is a stand-alone Git repository browser. It can be used to explore repos in
your browser of choice and features syntax highlighting with
[Pygments](http://pygments.org/),
[Markdown](http://daringfireball.net/projects/markdown/)/[org-mode](http://orgmode.org/)/[+++](https://github.com/github/markup/)
rendering, commit log and blame.

Dolt is also a library, designed to render Git trees, blobs, commit log and
blame. It can render said views with or without a layout, or you can provide
your own templates (through [Tilt](https://github.com/rtomayko/tilt/)). You can
also provide your own rendering implementation to render other formats than
templates outputting HTML.

Dolt is the implementation of the next generation repo browser to be used in the
[Gitorious](http://gitorious.org) software.

## Installing Dolt

To install `dolt` you need Ruby, RubyGems and Python development files. The
Python development files are required to support Pygments syntax highlighting.

Note: Dolt uses [libgit2](http://libgit2.github.com) and its Ruby bindings,
[Rugged](http://github.com/libgit2/rugged) for Git access where
feasible. Currently, ``Dolt`` relies on a version of `Rugged` that is not
yet released, so you have to build it yourself.
[See em-rugged instructions](http://github.com/cjohansen/em-rugged).

### Systems using apt (Debian/Ubuntu, others)

    # 1) Install Ruby (skip if you already have Ruby installed)
    sudo apt-get install ruby

    # 2) Install Python development files
    sudo apt-get install python-dev

    # 3) Install dolt. This may or may not require the use of sudo, depending on
    #    how you installed Ruby. This step assumes that you already built and
    #    installed em-rugged as explained above.
    sudo gem install dolt

### Systems using yum (Fedora/CentOS/RedHat, others)

    # 1) Install Ruby (skip if you already have Ruby installed)
    sudo yum install ruby

    # 2) Install Python development files
    sudo yum install python-devel

    # 3) Install dolt. This may or may not require the use of sudo, depending on
    #    how you installed Ruby. This step assumes that you already built and
    #    installed em-rugged as explained above.
    sudo gem install dolt

# The Dolt CLI

The `dolt` library installs a CLI that can be used to quickly browse either a
single (typically the current) repository, or multiple repositories.

## Browsing a single repository

In a git repository, issue the following command:

    $ dolt .

Then open a browser at [http://localhost:3000](http://localhost:3000). You will
be redirected to the root tree, and can browse the repository. To view trees and
blobs at specific refs, use the URL. A branch/tag selector will be added later.

## Browsing multiple repositories

The idea is that eventually, `dolt` should be able to serve up all Git
repositories managed by your Gitorious server. It does not yet do that, because
there currently is no "repository resolver" that understands the hashed paths
Gitorious uses.

Meanwhile, if you have a directory that contains multiple git repositories, you
can browse all of them through the same process by doing:

    $ dolt /path/to/repos

Now [http://localhost:3000/repo](http://localhost:3000/repo) will allow you to
browse the `/path/repos/repo` repository. As `dolt` matures, there will be a
listing of all repositories and more.

## Markup rendering

Dolt uses the [``GitHub::Markup``](https://github.com/github/markup/) library to
render certain markup formats as HTML. Dolt does not have a hard dependency on
any of the required gems to actually render markups, so see the
[``GitHub::Markup`` docs](https://github.com/github/markup/) for information on
what and how to install support for various languages.

# License

Dolt is free software licensed under the
[GNU Affero General Public License (AGPL)](http://www.gnu.org/licenses/agpl-3.0.html).
Dolt is developed as part of the Gitorious project.
