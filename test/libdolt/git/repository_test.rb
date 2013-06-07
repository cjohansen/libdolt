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
require "libdolt/git/repository"
require "time"
require "ostruct"
require "mocha/setup"

describe Dolt::Git::Repository do
  before { @repository = Dolt::Git::Repository.new(".") }

  describe "#submodules" do
    it "returns list of submodules" do
      submodules = @repository.submodules("c1f6cd9")
      url = "git://gitorious.org/gitorious/ui3.git"

      assert_equal [{ :path => "vendor/ui", :url => url }], submodules
    end

    it "returns empty array if no submodules" do
      submodules = @repository.submodules("26139a3")
      assert_equal [], submodules
    end
  end

  describe "#tree" do
    it "includes submodule data for trees" do
      tree = @repository.tree("3dc532f", "vendor")

      assert_equal({
          :type => :submodule,
          :filemode => 57344,
          :name => "ui",
          :oid => "d167e3e1c17a27e4cf459dd380670801b0659659",
          :url => "git://gitorious.org/gitorious/ui3.git"
        }, tree.entries.first)
    end
  end

  describe "#tree_entry" do
    it "includes submodule data for trees" do
      tree = @repository.tree_entry("3dc532f", "vendor")

      assert_equal({
          :type => :submodule,
          :filemode => 57344,
          :name => "ui",
          :oid => "d167e3e1c17a27e4cf459dd380670801b0659659",
          :url => "git://gitorious.org/gitorious/ui3.git"
        }, tree.entries.first)
    end

    it "returns blob" do
      blob = @repository.tree_entry("3dc532f", "Gemfile")

      assert blob.is_a?(Rugged::Blob)
      assert_equal "source \"http://rubygems.org\"\n\ngemspec\n", blob.content
    end
  end

  describe "#blame" do
    it "returns blame" do
      blame = @repository.blame("master", "Gemfile")
      assert Dolt::Git::Blame === blame
    end

    it "separates tree-like and path" do
      cmd = "git --git-dir #{@repository.path} blame -l -t -p master -- Gemfile"
      Dolt::Git.expects(:shell).with(cmd).returns(Dolt::FakeProcess.new(0))
      @repository.blame("master", "Gemfile")
    end

    it "does not allow injecting evil commands" do
      cmd = "git --git-dir #{@repository.path} blame -l -t -p master -- Gemfile\\; rm -fr /tmp"
      Dolt::Git.expects(:shell).with(cmd).returns(Dolt::FakeProcess.new(0))
      @repository.blame("master", "Gemfile; rm -fr /tmp")
    end
  end

  describe "#log" do
    it "returns commits" do
      log = @repository.log("master", "dolt.gemspec", 2)
      assert_equal 2, log.length
      assert Hash === log[0]
    end
  end

  describe "#tree_history" do
    it "fails if path is not a tree" do
      assert_raises Exception do |err|
        tree = @repository.tree_history("master", "Gemfile")
        assert_match /not a tree/, err.message
      end
    end

    it "fails if path does not exist in ref" do
      assert_raises Rugged::IndexerError do |err|
        tree = @repository.tree_history("26139a3", "test")
        assert_match /does not exist/, err.message
      end
    end

    it "returns tree with history" do
      log = @repository.tree_history("48ffbf7", "")

      assert_equal 11, log.length
      expected = {
        :type => :blob,
        :oid => "e90021f89616ddf86855d05337c188408d3b417e",
        :filemode => 33188,
        :name => ".gitmodules",
        :history => [{
            :oid => "906d67b4f3e5de7364ba9b57d174d8998d53ced6",
            :author => { :name => "Christian Johansen",
              :email => "christian@cjohansen.no" },
            :summary => "Working Moron server for viewing blobs",
            :date => Time.parse("Mon Sep 10 15:07:39 +0200 2012"),
            :message => ""
          }]
      }

      assert_equal expected, log[0]
    end

    it "returns nested tree with history" do
      log = @repository.tree_history("48ffbf7", "lib")

      expected = [{
          :type => :tree,
          :oid => "58f84405b588699b24c619aa4cd83669c5623f88",
          :filemode => 16384,
          :name => "dolt",
          :history => [{
              :oid => "8ab4f8c42511f727244a02aeee04824891610bbd",
              :author => { :name => "Christian Johansen",
                :email => "christian@gitorious.com" },
              :summary => "New version",
              :date => Time.parse("Mon Oct 1 16:34:00 +0200 2012"),
              :message => ""
            }]
        }]
      assert_equal expected, log
    end
  end

  describe "#readmes" do
    it "returns single readme" do
      def @repository.tree(ref, path)
        entries = [{ :type => :blob, :name => "Readme" },
                   { :type => :blob, :name => "file.txt" },
                   { :type => :tree, :name => "dir" }]
        if ref == "master" && path == ""
          OpenStruct.new(:entries => entries)
        else
          raise Exception.new("Wrong ref/path")
        end
      end

      readmes = @repository.readmes("master")

      assert_equal 1, readmes.length
      assert_equal "Readme", readmes.first[:name]
    end

    it "does not return trees" do
      def @repository.tree(ref, path)
        entries = [{ :type => :tree, :name => "Readme" },
                   { :type => :blob, :name => "file.txt" },
                   { :type => :tree, :name => "dir" }]
        OpenStruct.new(:entries => entries)
      end

      readmes = @repository.readmes("master")
      assert_equal 0, readmes.length
    end

    it "returns all readmes" do
      def @repository.tree(ref, path)
        entries = [{ :type => :blob, :name => "Readme.rdoc" },
                   { :type => :blob, :name => "readme" },
                   { :type => :blob, :name => "Readme.md" }]
        OpenStruct.new(:entries => entries)
      end

      readmes = @repository.readmes("master")
      assert_equal 3, readmes.length
    end

    it "returns empty array of readmes when looking up tree fails" do
      def @repository.tree(ref, path)
        raise Exception.new("Unknown reason")
      end

      readmes = @repository.readmes("master")
      assert_equal 0, readmes.length
    end

    it "finds readmes in a path" do
      def @repository.tree(ref, path)
        if path == "lib"
          entries = [{ :type => :blob, :name => "Readme.rdoc" }]
        else
          entries = []
        end
        OpenStruct.new(:entries => entries)
      end

      assert_equal 0, @repository.readmes("master").length
      assert_equal 1, @repository.readmes("master","lib").length
    end
  end
end
