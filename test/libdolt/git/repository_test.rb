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
  before { @repository = Dolt::Git::Repository.new(Dolt.fixture_repo_path) }

  describe "#submodules" do
    it "returns list of submodules" do
      submodules = @repository.submodules("60eebb9")
      url = "git://gitorious.org/gitorious/ui3.git"

      assert_equal [{ :path => "vendor/ui", :url => url }], submodules
    end

    it "returns empty array if no submodules" do
      submodules = @repository.submodules("fc5f5fb")
      assert_equal [], submodules
    end
  end

  describe "#tree" do
    it "includes submodule data for trees" do
      tree = @repository.tree("60eebb9", "vendor")

      assert_equal({
          :type => :submodule,
          :filemode => 57344,
          :name => "ui",
          :oid => "77c88454e83e59772e9bf460ef22251cc9d63f9f",
          :url => "git://gitorious.org/gitorious/ui3.git"
        }, tree.entries.first)
    end
  end

  describe "#tree_entry" do
    it "includes submodule data for trees" do
      tree = @repository.tree_entry("60eebb9", "vendor")

      assert_equal({
          :type => :submodule,
          :filemode => 57344,
          :name => "ui",
          :oid => "77c88454e83e59772e9bf460ef22251cc9d63f9f",
          :url => "git://gitorious.org/gitorious/ui3.git"
        }, tree.entries.first)
    end

    it "returns blob" do
      blob = @repository.tree_entry("fc5f5fb", "README.org")

      assert blob.is_a?(Rugged::Blob)
      assert_equal "* This is a readme\n  It even has some text in it\n", blob.content
    end
  end

  describe "#blame" do
    it "returns blame" do
      blame = @repository.blame("master", "README.org")
      assert Dolt::Git::Blame === blame
    end

    it "separates tree-like and path" do
      cmd = "git --git-dir #{@repository.path} blame -l -t -p master -- README.org"
      Dolt::Git.expects(:shell).with(cmd).returns(Dolt::FakeProcess.new(0))
      @repository.blame("master", "README.org")
    end

    it "does not allow injecting evil commands" do
      cmd = "git --git-dir #{@repository.path} blame -l -t -p master -- README.org\\; rm -fr /tmp"
      Dolt::Git.expects(:shell).with(cmd).returns(Dolt::FakeProcess.new(0))
      @repository.blame("master", "README.org; rm -fr /tmp")
    end
  end

  describe "#log" do
    it "returns commits" do
      log = @repository.log("master", "README.org", 2)
      assert_equal 2, log.length
      assert Hash === log[0]

      log = @repository.log("master", "README.org", 1)
      assert_equal 1, log.length
    end
  end

  describe "#tree_history" do
    it "fails if path is not a tree" do
      begin
        tree = @repository.tree_history("master", "README.org")
        raise "Should've raised an Exception"
      rescue Exception => err
        assert_match /not a tree/, err.message
      end
    end

    it "fails if path does not exist in ref" do
      begin
        tree = @repository.tree_history("fc5f5fb", "test")
        raise "Should've raised an Rugged::IndexerError"
      rescue Rugged::TreeError => err
        assert_match /does not exist/, err.message
      end
    end

    it "returns tree with history" do
      log = @repository.tree_history("e8d33ae", "")

      assert_equal 4, log.length
      expected = {
        :type => :blob,
        :oid => "e90021f89616ddf86855d05337c188408d3b417e",
        :filemode => 33188,
        :name => ".gitmodules",
        :history => [{
            :oid => "60eebb9021a6ce7d582c2f2d4aa5bfb3672150ae",
            :author => { :name => "Christian Johansen",
              :email => "christian@cjohansen.no" },
            :summary => "Add submodule",
            :date => Time.parse("Tue Jun 18 09:01:48 +0200 2013"),
            :message => ""
          }]
      }

      assert_equal expected, log[0]
    end

    it "returns nested tree with history" do
      log = @repository.tree_history("e8d33ae", "lib")

      expected = [{
          :type => :blob,
          :oid => "85026eda8302b98fa54cc24445a118028865a2e2",
          :filemode => 33188,
          :name => "foo.rb",
          :history => [{
              :oid => "fc5f5fb50b435e183925b341909610aace90a413",
              :author => { :name => "Marius Mathiesen",
                :email => "marius@gitorious.com" },
              :summary => "Stuff and stuff",
              :date => Time.parse("Tue Jun 11 13:10:31 +0200 2013"),
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
