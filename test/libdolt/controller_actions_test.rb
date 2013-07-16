# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++
require "test_helper"
require "libdolt/controller_actions"

describe Dolt::ControllerActions do
  describe "#blob" do
    it "delegates to lookup" do
      lookup = Test::Lookup.new(Stub::Blob.new)
      dolt = Dolt::ControllerActions.new(Test::Router.new, lookup, Test::Renderer.new)

      dolt.blob("gitorious", "master", "app/models/repository.rb")

      assert_equal "gitorious", lookup.repo
      assert_equal "master", lookup.ref
      assert_equal "app/models/repository.rb", lookup.path
    end

    it "renders the blob template as html" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Blob.new), Test::Renderer.new("Blob"))

      response = dolt.blob("gitorious", "master", "app/models/repository.rb")

      assert_equal "text/html; charset=utf-8", header(response, "Content-Type")
      assert_equal "blob:Blob", body(response)
    end

    it "renders the blob template with custom data" do
      renderer = Test::Renderer.new("Blob")
      dolt = Dolt::ControllerActions.new(Test::Router.new, Test::Lookup.new(Stub::Blob.new), renderer)

      dolt.blob("gitorious", "master", "app/models/repository.rb", { :who => 42 })

      assert_equal 42, renderer.data[:who]
    end

    it "redirects tree views to tree action" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Tree.new), Test::Renderer.new("Tree"))

      response = dolt.blob("gitorious", "master", "app/models")

      assert_equal 302, status(response)
      assert_equal "/gitorious/tree/master:app/models", header(response, "Location")
      assert_match "You are being ", body(response)
      assert_match "redirected", body(response)
    end

    it "unescapes ref" do
      lookup = Test::Lookup.new(Stub::Blob.new)
      dolt = Dolt::ControllerActions.new(Test::Router.new, lookup, Test::Renderer.new("Blob"))

      dolt.blob("gitorious", "issue-%23221", "app/my documents")

      assert_equal "issue-#221", lookup.ref
    end

    it "does not redirect ref to oid by default" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Blob.new), Test::Renderer.new("Blob"))

      response = dolt.blob("gitorious", "master", "lib/gitorious.rb")

      location = header(response, "Location")
      refute_equal 302, status(response)
      refute_equal 307, status(response)
    end

    it "redirects ref to oid if configured so" do
      router = Test::RedirectingRouter.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Blob.new), Test::Renderer.new("Blob"))

      response = dolt.blob("gitorious", "master", "lib/gitorious.rb")

      location = header(response, "Location")
      assert_equal 307, status(response)
      assert_equal "/gitorious/blob/#{'a' * 40}:lib/gitorious.rb", location
      assert_match "You are being", body(response)
    end
  end

  describe "#tree" do
    it "delegates to actions" do
      lookup = Test::Lookup.new(Stub::Tree.new)
      dolt = Dolt::ControllerActions.new(Test::Router.new, lookup, Test::Renderer.new)

      dolt.tree("gitorious", "master", "app/models")

      assert_equal "gitorious", lookup.repo
      assert_equal "master", lookup.ref
      assert_equal "app/models", lookup.path
    end

    it "renders the tree template as html" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Tree.new), Test::Renderer.new("Tree"))

      response = dolt.tree("gitorious", "master", "app/models")

      assert_equal "text/html; charset=utf-8", header(response, "Content-Type")
      assert_equal "tree:Tree", body(response)
    end

    it "renders template with custom data" do
      renderer = Test::Renderer.new("Tree")
      dolt = Dolt::ControllerActions.new(Test::Router.new, Test::Lookup.new(Stub::Tree.new), renderer)

      dolt.tree("gitorious", "master", "app/models", { :who => 42 })

      assert_equal 42, renderer.data[:who]
    end

    it "redirects blob views to blob action" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Blob.new), Test::Renderer.new("Tree"))

      response = dolt.tree("gitorious", "master", "app/models/repository.rb")

      location = header(response, "Location")
      assert_equal 302, status(response)
      assert_equal "/gitorious/blob/master:app/models/repository.rb", location
      assert_match "You are being", body(response)
    end

    it "sets X-UA-Compatible header" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Tree.new), Test::Renderer.new("Tree"))

      response = dolt.tree("gitorious", "master", "app/models")

      assert_equal "IE=edge", header(response, "X-UA-Compatible")
    end

    it "does not set cache-control header for head ref" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Tree.new), Test::Renderer.new("Tree"))

      response = dolt.tree("gitorious", "master", "app/models")

      assert_nil header(response, "Cache-Control")
    end

    it "sets cache headers for full oid ref" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Tree.new), Test::Renderer.new("Tree"))

      response = dolt.tree("gitorious", "a" * 40, "app/models")

      assert_equal "max-age=315360000, public", header(response, "Cache-Control")
      refute_nil header(response, "Expires")
    end

    it "unescapes ref" do
      lookup = Test::Lookup.new(Stub::Tree.new)
      dolt = Dolt::ControllerActions.new(Test::Router.new, lookup, Test::Renderer.new("Tree"))

      dolt.tree("gitorious", "issue-%23221", "app")

      assert_equal "issue-#221", lookup.ref
    end

    it "redirects ref to oid if configured so" do
      router = Test::RedirectingRouter.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Tree.new), Test::Renderer.new("Tree"))

      response = dolt.tree("gitorious", "master", "lib")

      assert_equal 307, status(response)
      assert_equal "/gitorious/tree/#{'a' * 40}:lib", header(response, "Location")
    end
  end

  describe "#tree_entry" do
    it "renders trees with the tree template as html" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Tree.new), Test::Renderer.new("Tree"))

      response = dolt.tree_entry("gitorious", "master", "app/models")

      assert_equal "text/html; charset=utf-8", header(response, "Content-Type")
      assert_equal "tree:Tree", body(response)
    end

    it "renders template with custom data" do
      renderer = Test::Renderer.new("Tree")
      dolt = Dolt::ControllerActions.new(Test::Router.new, Test::Lookup.new(Stub::Tree.new), renderer)

      dolt.tree_entry("gitorious", "master", "app/models", { :who => 42 })

      assert_equal 42, renderer.data[:who]
    end

    it "renders trees with the tree template as html" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Blob.new), Test::Renderer.new("Blob"))

      response = dolt.tree_entry("gitorious", "master", "app/models")

      assert_equal "text/html; charset=utf-8", header(response, "Content-Type")
      assert_equal "blob:Blob", body(response)
    end

    it "unescapes ref" do
      lookup = Test::Lookup.new(Stub::Tree.new)
      dolt = Dolt::ControllerActions.new(Test::Router.new, lookup, Test::Renderer.new("Tree"))

      dolt.tree_entry("gitorious", "issue-%23221", "app")

      assert_equal "issue-#221", lookup.ref
    end

    it "redirects ref to oid if configured so" do
      router = Test::RedirectingRouter.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Tree.new), Test::Renderer.new("Tree"))

      response = dolt.tree_entry("gitorious", "master", "lib")

      assert_equal 307, status(response)
      assert_equal "/gitorious/source/#{'a' * 40}:lib", header(response, "Location")
    end
  end

  describe "#raw" do
    it "delegates to lookup" do
      lookup = Test::Lookup.new(Stub::Blob.new)
      dolt = Dolt::ControllerActions.new(Test::Router.new, lookup, Test::Renderer.new)

      dolt.raw("gitorious", "master", "app/models/repository.rb")

      assert_equal "gitorious", lookup.repo
      assert_equal "master", lookup.ref
      assert_equal "app/models/repository.rb", lookup.path
    end

    it "renders the raw template as text" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Blob.new), Test::Renderer.new("Text"))

      response = dolt.raw("gitorious", "master", "app/models/repository.rb")

      assert_equal "text/plain", header(response, "Content-Type")
      assert_equal "raw:Text", body(response)
    end

    it "renders template with custom data" do
      renderer = Test::Renderer.new("Text")
      dolt = Dolt::ControllerActions.new(Test::Router.new, Test::Lookup.new(Stub::Blob.new), renderer)

      dolt.raw("gitorious", "master", "app/models/repository.rb", { :who => 42 })

      assert_equal 42, renderer.data[:who]
    end

    it "redirects tree views to tree action" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Tree.new), Test::Renderer.new("Tree"))

      response = dolt.raw("gitorious", "master", "app/models")

      location = header(response, "Location")
      assert_equal 302, status(response)
      assert_equal "/gitorious/tree/master:app/models", location
      assert_match "You are being", body(response)
    end

    it "unescapes ref" do
      lookup = Test::Lookup.new(Stub::Blob.new)
      dolt = Dolt::ControllerActions.new(Test::Router.new, lookup, Test::Renderer.new("Blob"))

      dolt.raw("gitorious", "issue-%23221", "app/models/repository.rb")

      assert_equal "issue-#221", lookup.ref
    end

    it "redirects ref to oid if configured so" do
      router = Test::RedirectingRouter.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Blob.new), Test::Renderer.new("Blob"))

      response = dolt.raw("gitorious", "master", "lib/gitorious.rb")

      assert_equal 307, status(response)
      assert_equal "/gitorious/raw/#{'a' * 40}:lib/gitorious.rb", header(response, "Location")
    end
  end

  describe "#blame" do
    it "delegates to lookup" do
      lookup = Test::Lookup.new(Stub::Blob.new)
      dolt = Dolt::ControllerActions.new(Test::Router.new, lookup, Test::Renderer.new)

      dolt.blame("gitorious", "master", "app/models/repository.rb")

      assert_equal "gitorious", lookup.repo
      assert_equal "master", lookup.ref
      assert_equal "app/models/repository.rb", lookup.path
    end

    it "renders the blame template as html" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Blob.new), Test::Renderer.new("Text"))

      response = dolt.blame("gitorious", "master", "app/models/repository.rb")

      assert_equal "text/html; charset=utf-8", header(response, "Content-Type")
      assert_equal "blame:Text", body(response)
    end

    it "renders template with custom data" do
      renderer = Test::Renderer.new("Text")
      dolt = Dolt::ControllerActions.new(Test::Router.new, Test::Lookup.new(Stub::Blob.new), renderer)

      dolt.blame("gitorious", "master", "app/models/repository.rb", { :who => 42 })

      assert_equal 42, renderer.data[:who]
    end

    it "unescapes ref" do
      lookup = Test::Lookup.new(Stub::Blob.new)
      dolt = Dolt::ControllerActions.new(Test::Router.new, lookup, Test::Renderer.new("Blob"))

      dolt.blame("gitorious", "issue-%23221", "app/models/repository.rb")

      assert_equal "issue-#221", lookup.ref
    end

    it "redirects ref to oid if configured so" do
      router = Test::RedirectingRouter.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Blob.new), Test::Renderer.new("Blob"))

      response = dolt.blame("gitorious", "master", "lib/gitorious.rb")

      assert_equal 307, status(response)
      assert_equal "/gitorious/blame/#{'a' * 40}:lib/gitorious.rb", header(response, "Location")
    end
  end

  describe "#history" do
    it "delegates to lookup" do
      lookup = Test::Lookup.new(Stub::Blob.new)
      dolt = Dolt::ControllerActions.new(Test::Router.new, lookup, Test::Renderer.new)
      dolt.history("gitorious", "master", "app/models/repository.rb", 10)

      assert_equal "gitorious", lookup.repo
      assert_equal "master", lookup.ref
      assert_equal "app/models/repository.rb", lookup.path
    end

    it "renders the commits template as html" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Blob.new), Test::Renderer.new("Text"))

      response = dolt.history("gitorious", "master", "app/models/repository.rb", 10)

      assert_equal "text/html; charset=utf-8", header(response, "Content-Type")
      assert_equal "commits:Text", body(response)
    end

    it "renders template with custom data" do
      renderer = Test::Renderer.new("Text")
      dolt = Dolt::ControllerActions.new(Test::Router.new, Test::Lookup.new(Stub::Blob.new), renderer)

      dolt.history("gitorious", "master", "app/models/repository.rb", 10, { :who => 42 })

      assert_equal 42, renderer.data[:who]
    end

    it "unescapes ref" do
      lookup = Test::Lookup.new(Stub::Blob.new)
      dolt = Dolt::ControllerActions.new(Test::Router.new, lookup, Test::Renderer.new("Blob"))

      dolt.history("gitorious", "issue-%23221", "lib/gitorious.rb", 10)

      assert_equal "issue-#221", lookup.ref
    end

    it "redirects ref to oid if configured so" do
      router = Test::RedirectingRouter.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Blob.new), Test::Renderer.new("Blob"))

      response = dolt.history("gitorious", "master", "lib/gitorious.rb", 10)

      assert_equal 307, status(response)
      assert_equal "/gitorious/history/#{'a' * 40}:lib/gitorious.rb", header(response, "Location")
    end
  end

  describe "#refs" do
    it "renders the refs template as json" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Blob.new), Test::Renderer.new("JSON"))

      response = dolt.refs("gitorious")

      assert_equal "application/json", header(response, "Content-Type")
      assert_equal "refs:JSON", body(response)
    end

    it "renders template with custom data" do
      renderer = Test::Renderer.new("Text")
      dolt = Dolt::ControllerActions.new(Test::Router.new, Test::Lookup.new(Stub::Blob.new), renderer)

      dolt.refs("gitorious", { :who => 42 })

      assert_equal 42, renderer.data[:who]
    end
  end

  describe "#tree_history" do
    it "renders the tree_history template as json" do
      router = Test::Router.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Tree.new), Test::Renderer.new("JSON"))

      response = dolt.tree_history("gitorious", "master", "", 1)

      assert_equal "application/json", header(response, "Content-Type")
      assert_equal "tree_history:JSON", body(response)
    end

    it "renders template with custom data" do
      renderer = Test::Renderer.new("Text")
      dolt = Dolt::ControllerActions.new(Test::Router.new, Test::Lookup.new(Stub::Tree.new), renderer)

      dolt.tree_history("gitorious", "master", "app/models", 1, { :who => 42 })

      assert_equal 42, renderer.data[:who]
    end

    it "unescapes ref" do
      lookup = Test::Lookup.new(Stub::Tree.new)
      dolt = Dolt::ControllerActions.new(Test::Router.new, lookup, Test::Renderer.new("Tree"))

      dolt.tree_history("gitorious", "issue-%23221", "app/models")

      assert_equal "issue-#221", lookup.ref
    end

    it "redirects ref to oid if configured so" do
      router = Test::RedirectingRouter.new
      dolt = Dolt::ControllerActions.new(router, Test::Lookup.new(Stub::Tree.new), Test::Renderer.new("Tree"))

      response = dolt.tree_history("gitorious", "master", "lib", 10)

      assert_equal 307, status(response)
      assert_equal "/gitorious/tree_history/#{'a' * 40}:lib", header(response, "Location")
    end
  end

  def status(response)
    response[0]
  end

  def header(response, name)
    response[1][name]
  end

  def body(response)
    response[2].join
  end
end
