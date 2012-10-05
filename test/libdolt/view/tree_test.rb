# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
require "libdolt/view/single_repository"
require "libdolt/view/object"
require "libdolt/view/tree"
require "ostruct"

describe Dolt::View::Tree do
  include Dolt::Html
  include Dolt::View::SingleRepository
  include Dolt::View::Object
  include Dolt::View::Tree

  describe "#tree_entries" do
    before do
      async = { :name => "async", :type => :tree }
      disk_repo_resolver = { :type => :blob, :name => "disk_repo_resolver.rb" }
      git = { :type => :tree, :name => "git" }
      repo_actions = { :type => :blob, :name => "repo_actions.rb" }
      sinatra = { :type => :tree, :name => "sinatra" }
      version = { :type => :blob, :name => "version.rb" }
      view_rb = { :type => :blob, :name => "view.rb" }
      view = { :type => :tree, :name => "view" }
      @tree = OpenStruct.new({ :entries => [async, disk_repo_resolver, git,
                                            repo_actions, sinatra, version,
                                            view_rb, view] })
    end

    it "groups tree by type, dirs first" do
      entries = tree_entries(@tree)

      assert_equal :tree, entries[0][:type]
      assert_equal :tree, entries[1][:type]
      assert_equal :tree, entries[2][:type]
      assert_equal :tree, entries[3][:type]
      assert_equal :blob, entries[4][:type]
      assert_equal :blob, entries[5][:type]
      assert_equal :blob, entries[6][:type]
      assert_equal :blob, entries[7][:type]
    end

    it "sorts by name" do
      entries = tree_entries(@tree)

      assert_equal "async", entries[0][:name]
      assert_equal "git", entries[1][:name]
      assert_equal "sinatra", entries[2][:name]
      assert_equal "view", entries[3][:name]
      assert_equal "disk_repo_resolver.rb", entries[4][:name]
      assert_equal "repo_actions.rb", entries[5][:name]
      assert_equal "version.rb", entries[6][:name]
      assert_equal "view.rb", entries[7][:name]
    end

    it "lumps submodules in with directories" do
      async = { :name => "async", :type => :tree }
      disk_repo_resolver = { :type => :blob, :name => "disk_repo_resolver.rb" }
      git = { :type => :submodule, :name => "git" }
      tree = OpenStruct.new({ :entries => [async, disk_repo_resolver, git] })
      entries = tree_entries(tree)

      assert_equal :tree, entries[0][:type]
      assert_equal :submodule, entries[1][:type]
      assert_equal :blob, entries[2][:type]
    end
  end

  describe "#partition_path" do
    it "partitions root into double array" do
      parts = partition_path("")
      assert_equal [[""]], parts

      parts = partition_path("/")
      assert_equal [[""]], parts

      parts = partition_path("./")
      assert_equal [[""]], parts
    end

    it "partitions single directory" do
      parts = partition_path("lib")
      assert_equal [["", "lib"]], parts
    end

    it "partitions two directories" do
      parts = partition_path("lib/dolt")
      assert_equal [["", "lib"], ["dolt"]], parts
    end

    it "partitions multiple directories" do
      parts = partition_path("lib/dolt/git/help")
      assert_equal [["", "lib"], ["dolt"], ["git"], ["help"]], parts
    end

    it "ignore trailing slash" do
      parts = partition_path("lib/dolt/")
      assert_equal [["", "lib"], ["dolt"]], parts
    end

    it "chunks up leading path" do
      parts = partition_path("lib/dolt/very/deep", 3)
      assert_equal [["", "lib", "dolt"], ["very"], ["deep"]], parts
    end

    it "partitions short path with maxdepth" do
      parts = partition_path("lib", 3)
      assert_equal [["", "lib"]], parts
    end
  end

  describe "#accumulate_path" do
    it "accumulates partitioned path" do
      parts = accumulate_path(partition_path("lib/dolt/very/deep", 3))
      assert_equal [["", "lib", "lib/dolt"], ["lib/dolt/very"], ["lib/dolt/very/deep"]], parts
    end
  end

  describe "#tree_context" do
    def context(path, maxdepth = nil)
      tree_context("gitorious", "master", accumulate_path(partition_path(path, maxdepth)))
    end

    it "renders root as empty string" do
      assert_equal "", context("")
      assert_equal "", context("/")
      assert_equal "", context("./")
    end

    it "renders single path item as table row" do
      assert_equal 1, select(context("lib"), "tr").length
      assert_equal 1, select(context("./lib"), "tr").length
    end

    it "includes link to root in single table row" do
      assert_equal 2, select(context("lib"), "a").length
    end

    it "renders single path item in cell" do
      assert_equal 1, select(context("lib"), "td").length
    end

    it "renders single path item as link" do
      # Two, because there's always a link to the root directory
      assert_equal 2, select(context("lib"), "a").length
      assert_match /lib/, select(context("lib"), "a")[1]
    end

    it "renders single path item with open folder icon" do
      assert_match /icon-folder-open/, select(context("lib"), "i").first
    end

    it "renders two path items as two table rows" do
      assert_equal 2, select(context("lib/dolt"), "tr").length
    end

    it "renders two path items with colspan in first row" do
      assert_match /colspan="6"/, select(context("lib/dolt"), "tr").first
      assert_match /colspan="5"/, select(context("lib/dolt"), "tr")[1]
      tr = select(context("lib/dolt"), "tr")[1]
      assert_equal 2, select(tr, "td").length
    end

    it "renders condensed first entry with slashes" do
      links = select(context("src/phorkie/Database/Adapter", 3), "a")

      assert_equal "<a href=\"/tree/master:\"><i class=\"icon icon-folder-open\"></i> /</a>", links.first
      assert_equal "<a href=\"/tree/master:src\"> src</a>", links[1]
      assert_equal "<a href=\"/tree/master:src/phorkie\">/ phorkie</a>", links[2]
    end

    it "renders long condensed first entry with slashes" do
      links = select(context("src/phorkie/Database/Adapter/Elasticsearch", 3), "a")

      assert_equal "<a href=\"/tree/master:\"><i class=\"icon icon-folder-open\"></i> /</a>", links.first
      assert_equal "<a href=\"/tree/master:src\"> src</a>", links[1]
      assert_equal "<a href=\"/tree/master:src/phorkie\">/ phorkie</a>", links[2]
      assert_equal "<a href=\"/tree/master:src/phorkie/Database\">/ Database</a>", links[3]
    end
  end
end
