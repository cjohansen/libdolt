# libdolt - Git repository browser internals

<a href="http://travis-ci.org/cjohansen/libdolt" class="travis">
  <img src="https://secure.travis-ci.org/cjohansen/libdolt.png">
</a>

`libdolt` is all the reusable internal workings of the
[Dolt repository browser](https://gitorious.org/gitorious/dolt). It provides all
the mechanics for retrieving the data you need display Git trees, blobs, blame
and more, and also includes tools to render them in a web context.

`libdolt` does not depend on Sinatra, or any other web context, so it can easily
be embedded in other frameworks/apps. Most notably, `libdolt` is used as the
repository browser in [Gitorious 3](https://gitorious.org/gitorious/mainline),
and as a stand-alone repository browser in [Dolt](https://gitorious.org/gitorious/dolt).

## Installing libdolt

libdolt depends on two system packages to do its job.

### Systems using apt (Debian/Ubuntu, others)

    # 1) Install Python development files
    sudo apt-get install -y python-dev libicu-dev

    # 2) Install dolt. This may or may not require the use of sudo, depending on
    #    how you installed Ruby.
    gem install libdolt

### Systems using yum (Fedora/CentOS/RedHat, others)

    # 1) Install Python development files
    sudo yum install -y python-devel libicu-devel

    # 3) Install dolt. This may or may not require the use of sudo, depending on
    #    how you installed Ruby.
    gem install dolt

## API

`libdolt` provides two main abstractions you may be interested in:

* `Dolt::RepositoryLookup` provides an API that will fetch various bits of
  information from your git repository, and returns a hash of data. This hash
  can typically be used for rendering in a template of some sort.
* `Dolt::ControllerActions` provides a web front-end to the repository lookup.
  It will use the lookup class to fetch the information it needs, and then it
  will render them using [Tiltout](https://gitorious.org/gitorious/tiltout). If
  you're looking to make a web-based repository browser, you can use this class
  in a Sinatra, Rack or Rails application, provide you own templates etc.

## Repository lookups

The `Dolt::RepositoryLookup` class provides many methods that use
[libgit2/Rugged](https://github.com/libgit2/rugged) in conjunction with the
classes found in `lib/libdolt/git` to fetch, consolidate and prepare Git
repository data in a display-friendly way. All methods return a hash.

The repository lookup class depends on a "repository resolver". This is an
object that can take a string from the URL, such as `"gitorious/mainline"` and
return a usable repository object. The repository object is expected to conform
to the `Dolt::Git::Repository` interface. Typically you will want to instantiate
this object, but you can in theory provide your own implementation, so long as
you maintain the interface.

Repository resolvers are quite simple animals. Here's an example of how to make
Dolt work with Gitorious' Repository model objects:

```rb
module Gitorious
  module Dolt
    class RepositoryResolver
      # How you initialize your objects is up to you - Dolt doesn't care, it
      # only ever sees the instance, not the class itself.
      def initialize(scope = ::Repository)
        @scope = scope
      end

      def resolve(repo)
        repository = @scope.find_by_path(repo)
        raise ActiveRecord::RecordNotFound.new if repository.nil?
        Gitorious::Dolt::Repository.new(repository)
      end
    end
  end
end
```

### Common data

All actions return a hash that include these keys:

* `path` - The repository-relative path
* `ref` - The ref or object id

### Example: Looking up a tree

```rb
resolver = Gitorious::Dolt::RepositoryResolver.new
lookup = Dolt::RepositoryLookup.new(resolver)

data = lookup.tree("gitorious/mainline", "master", "")
#=> {
#  :path => "",
#  :ref => "master",
#  :tree => #<Rugged::Tree:16209820 {oid: 89cd7e9d4564928de6b803b36c6e3d081c8d9ca1}>
#     <"README.org" b40c249db94476cac7fa91a9d6491c0faf21ec21>
#     <"lib" 264c348a80906538018616fa16fc35d04bdf38b0>,
#  :readme => { :blob => #<Rugged::Blob:0x00000002111460>, :path => "README.org" }
# }
```

Note that the `tree` lookup will include a readme blob if one is available, and
Dolt is able to render it.

## Controller actions

The controller actions that ship with libdolt are web framework agnostic. They
return arrays that can be passed directly to Rack, or can be picked apart for
further processing. The controller actions can be configured to redirect any
request for symbolic refs (e.g. a request for something on "master" will
redirect to the current tip of that branch), and it provides error handling,
renders blobs with syntax highlighting and more.

The controller actions have three dependencies: a router, a repository lookup
instance (see above) and a renderer.

The router is expected to respond to these messages:

* `tree_url(repo, ref, path)`
* `blob_url(repo, ref, path)`
* `tree_entry_url(repo, ref, path)`
* `blame_url(repo, ref, path)`
* `history_url(repo, ref, path)`
* `tree_history_url(repo, ref, path)`
* `raw_url(repo, ref, path)`

The renderer can be anything that understands this message:

```rb
renderer.render(template, data, template_options)

# e.g.
renderer.render("tree", {
  :ref => "master",
  :path => lib",
  :tree => tree
}, { :layout => "dark_skin" })
```

[Tiltout](https://gitorious.org/gitorious/tiltout) is well suited for the task.
To just use the built-in templates in libdolt:

```rb
renderer = Tiltout.new(Dolt.template_dir, { :layout => "layout" })
renderer.helper(Dolt::View::Object)
renderer.helper(Dolt::View::Urls)
renderer.helper(Dolt::View::Blob)
renderer.helper(Dolt::View::Blame)
renderer.helper(Dolt::View::Breadcrumb)
renderer.helper(Dolt::View::Tree)
renderer.helper(Dolt::View::Commit)
renderer.helper(Dolt::View::Gravatar)
renderer.helper(Dolt::View::TabWidth)
renderer.helper(Dolt::View::BinaryBlobEmbedder)
renderer.helper(:tab_width => options[:tab_width], :maxdepth => 3)

actions = Dolt::ControllerActions.new(some_router, lookup, renderer)
response = actions.blob("gitorious/libdolt", "master", "Readme.md")

#=> [200, {
  "Content-Type" => "text/html; charset=utf-8",
  "X-UA-Compatible" => "IE=edge"
}, [html...]]
```

The controller actions also accept a last argument, which is a hash of
additional data to expose to the templates. This is useful if you are using
a custom layout and/or templates.

## Markup rendering

Dolt uses the [``GitHub::Markup``](https://github.com/github/markup/) library
(through [Makeup](https://gitorious.org/gitorious/makeup)) to render certain
markup formats as HTML. Dolt does not have a hard dependency on any of the
required gems to actually render markups, so see the
[``GitHub::Markup`` docs](https://github.com/github/markup/) for information on
what and how to install support for various languages.

Various rendering techniques are implemented as modules that can be included in
you Tiltout views. Here's an excerpt from Dolt's `bin/dolt` script (which runs a
standalone repository browser locally on your box):

```rb
# Attempt to syntax highlight every blob
# renderer.helper(Dolt::View::SyntaxHighlight)

# Attempt to render every blob as markup
# renderer.helper(Dolt::View::Markup)

# Render supported formats as markup, syntax highlight the rest
# (if attempting to render some format as markup crashes, it will
# fall back to syntax highlighting)
renderer.helper(Dolt::View::SmartBlobRenderer)
```

# License

libdolt is free software licensed under the
[GNU Affero General Public License (AGPL)](http://www.gnu.org/licenses/agpl-3.0.html).
libdolt is developed as part of the Gitorious project.
