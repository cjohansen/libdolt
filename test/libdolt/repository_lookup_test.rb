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
require "libdolt/repository_lookup"
require "ostruct"
require "mocha/setup"

class Resolver
  attr_reader :resolved
  def initialize; @resolved = []; end

  def resolve(repo)
    repository = Dolt::Git::Repository.new(Dolt.fixture_repo_path)
    @resolved << repository
    repository
  end
end

class MetaResolver < Resolver
  def resolve(repo)
    repository = super
    def repository.meta
      "Meta data is cool"
    end
    repository
  end
end

describe Dolt::RepositoryLookup do
  before do
    @resolver = Resolver.new
    @lookup = Dolt::RepositoryLookup.new(@resolver)
  end

  describe "#blob" do
    it "returns path, blob, repo, ref, filemode and base_tree_url" do
      data = @lookup.blob("gitorious", "fc5f5fb50b435e18", "lib/foo.rb")
      assert_equal "gitorious", data[:repository_slug]
      assert_equal "fc5f5fb50b435e18", data[:ref]
      assert Rugged::Blob === data[:blob]
      assert_equal "100644", data[:filemode]
    end

    it "looks up blob by sha1" do
      data = @lookup.blob("gitorious", "c035ba24bb3bed31589bc6736ca9b116175eb723", "README.org")
      assert_equal "gitorious", data[:repository_slug]
      assert_equal "c035ba24bb3bed31589bc6736ca9b116175eb723", data[:ref]
      assert Rugged::Blob === data[:blob]
      assert_equal "100644", data[:filemode]
    end
  end

  describe "#tree" do
    it "returns tree, repo and ref" do
      data = @lookup.tree("gitorious", "fc5f5fb50b435e18", "lib")
      repo = @resolver.resolved.last
      assert_equal "264c348a80906538018616fa16fc35d04bdf38b0", data[:tree].oid
      assert_equal "fc5f5fb50b435e18", data[:ref]
      assert_equal "lib", data[:path]
    end
  end

  describe "readmes" do
    it "includes readmes which can be rendered" do
      readme_name = "README.org"
      Makeup::Markup.stubs(:can_render?).with(readme_name).returns(true)
      data = @lookup.tree("gitorious","fc5f5fb50b435e18","")
      repo = @resolver.resolved.last
      assert_equal "#{readme_name}", data[:readme][:path]
    end
  end

  describe "#tree_entry" do
    it "returns tree, repo and ref" do
      data = @lookup.tree_entry("gitorious", "fc5f5fb50b435e18", "")
      repo = @resolver.resolved.last
      assert_equal :tree, data[:type]
    end

    it "returns blob, filemode, repo and ref" do
      data = @lookup.tree_entry("gitorious", "fc5f5fb50b435e18", "lib/foo.rb")

      assert_equal "lib/foo.rb", data[:path]
      assert_equal "fc5f5fb50b435e18", data[:ref]
      assert_equal :blob, data[:type]
      assert_equal "100644", data[:filemode]
    end
  end

  describe "#blame" do
    it "resolves repository" do
      @lookup.blame("gitorious", "master", "lib")
      assert_equal 1, @resolver.resolved.size
    end

    it "returns blame, filemode, repo and ref" do
      data = @lookup.blame("gitorious", "fc5f5fb50b435e18", "lib")
      assert Dolt::Git::Blame === data[:blame]
      assert_equal "gitorious", data[:repository_slug]
      assert_equal "fc5f5fb50b435e18", data[:ref]
      assert_equal "lib", data[:path]
      assert_equal "40000", data[:filemode]
    end
  end

  describe "#history" do
    it "returns commits, repo and ref" do
      data = @lookup.history("gitorious", "fc5f5fb50b435e18", "app", 2)

      assert_equal({
          :commits => [],
          :repository_slug => "gitorious",
          :ref =>  "fc5f5fb50b435e18",
          :path => "app"
        }, data)
    end
  end

  describe "#refs" do
    it "returns repositories, tags and heads" do
      data = @lookup.refs("gitorious")

      assert data[:tags].detect {|name, ref|
        name == "testable-tag" && ref == "fc5f5fb50b435e183925b341909610aace90a413"
      }
    end
  end

  describe "#tree_history" do
    it "returns repository, path, ref and history" do
      data = @lookup.tree_history("gitorious", "testable-tag", "", 1)
      assert_equal "testable-tag", data[:ref]
      assert_equal 2, data[:tree].length
      assert_equal "", data[:path]
    end
  end

  describe "repository meta data" do
    it "is returned with other data" do
      resolver = MetaResolver.new
      lookup = Dolt::RepositoryLookup.new(resolver)
      data = lookup.blob("gitorious", "fc5f5fb50b435e18", "lib")

      assert_equal "Meta data is cool", data[:repository_meta]
    end
  end

  describe "#rev_parse_oid" do
    it "resolves ref oid" do
      oid = "fc5f5fb50b435e183925b341909610aace90a413"
      assert_equal oid, @lookup.rev_parse_oid("gitorious", "testable-tag")
    end
 end
end
