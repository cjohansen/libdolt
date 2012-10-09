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
require "libdolt/git/repository"
require "time"

describe Dolt::Git::Repository do
  include EM::MiniTest::Spec
  before { @repository = Dolt::Git::Repository.new(".") }

  describe "#submodules" do
    it "returns deferrable" do
      deferrable = @repository.submodules("master")
      assert deferrable.respond_to?(:callback)
      assert deferrable.respond_to?(:errback)
    end

    it "yields list of submodules" do
      @repository.submodules("c1f6cd9").callback do |submodules|
        url = "git://gitorious.org/gitorious/ui3.git"
        assert_equal [{ :path => "vendor/ui", :url => url }], submodules
        done!
      end
    wait!
    end

    it "resolves with empty array if no submodules" do
      @repository.submodules("26139a3").callback do |submodules|
        assert_equal [], submodules
        done!
      end
      wait!
    end
  end

  describe "#tree" do
    it "includes submodule data for trees" do
      @repository.tree("3dc532f", "vendor").callback do |tree|
        assert_equal({
          :type => :submodule,
          :filemode => 57344,
          :name => "ui",
          :oid => "d167e3e1c17a27e4cf459dd380670801b0659659",
          :url => "git://gitorious.org/gitorious/ui3.git"
        }, tree.entries.first)
        done!
      end
      wait!
    end
  end

  describe "#tree_entry" do
    it "includes submodule data for trees" do
      @repository.tree_entry("3dc532f", "vendor").callback do |tree|
        assert_equal({
          :type => :submodule,
          :filemode => 57344,
          :name => "ui",
          :oid => "d167e3e1c17a27e4cf459dd380670801b0659659",
          :url => "git://gitorious.org/gitorious/ui3.git"
        }, tree.entries.first)
        done!
      end
      wait!
    end

    it "yields blob" do
      @repository.tree_entry("3dc532f", "Gemfile").callback do |blob|
        assert blob.is_a?(Rugged::Blob)
        assert_equal "source \"http://rubygems.org\"\n\ngemspec\n", blob.content
        done!
      end
      wait!
    end
  end

  describe "#blame" do
    it "returns deferrable" do
      deferrable = @repository.blame("master", "Gemfile")
      assert deferrable.respond_to?(:callback)
      assert deferrable.respond_to?(:errback)
    end

    it "yields blame" do
      @repository.blame("master", "Gemfile").callback do |blame|
        assert Dolt::Git::Blame === blame
        done!
      end
      wait!
    end
  end

  describe "#log" do
    it "returns deferrable" do
      deferrable = @repository.log("master", "Gemfile", 1)
      assert deferrable.respond_to?(:callback)
      assert deferrable.respond_to?(:errback)
    end

    it "yields commits" do
      @repository.log("master", "dolt.gemspec", 2).callback do |log|
        assert_equal 2, log.length
        assert Hash === log[0]
        done!
      end
      wait!
    end
  end

  describe "#tree_history" do
    it "returns deferrable" do
      deferrable = @repository.tree_history("master", "")
      assert deferrable.respond_to?(:callback)
      assert deferrable.respond_to?(:errback)
    end

    it "fails if path is not a tree" do
      deferrable = @repository.tree_history("master", "Gemfile")
      deferrable.errback do |err|
        assert_match /not a tree/, err.message
        done!
      end
      wait!
    end

    it "fails if path does not exist in ref" do
      deferrable = @repository.tree_history("26139a3", "test")
      deferrable.errback do |err|
        assert_match /does not exist/, err.message
        done!
      end
      wait!
    end

    it "yields tree with history" do
      promise = @repository.tree_history("48ffbf7", "")

      promise.callback do |log|
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
        done!
      end

      promise.errback do |err|
        puts "FAILED! #{err.inspect}"
      end

      wait!
    end

    it "yields nested tree with history" do
      promise = @repository.tree_history("48ffbf7", "lib")

      promise.callback do |log|
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
        done!
      end

      promise.errback do |err|
        puts "FAILED! #{err.inspect}"
      end

      wait!
    end
  end
end
