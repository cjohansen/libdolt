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
require "libdolt/repo_actions"
require "ostruct"
require "mocha/setup"

class Repository
  attr_reader :name
  def initialize(name)
    @name = name
  end

  def tree(ref, path); end
  def tree_entry(ref, path); end
  def rev_parse(rev); end
  def rev_parse_oid(ref); self.class.refs[ref] || nil; end
  def blame(ref, path); end
  def log(ref, path, limit); end
  def refs; end
  def tree_history(ref, path, count); end
  def readmes(ref, path); []; end

  def self.stub_ref(name, ref)
    self.refs[name] = ref
  end

  def self.refs
    @refs ||= {}
  end
end

class Resolver
  attr_reader :resolved
  def initialize; @resolved = []; end

  def resolve(repo)
    repository = Repository.new(repo)
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

class FakeBlob; end

describe Dolt::RepoActions do
  before do
    @resolver = Resolver.new
    @actions = Dolt::RepoActions.new(@resolver)
    @blob = FakeBlob.new
    @tree = { :type => :tree }
    @blame = { :type => :blame }
  end

  describe "#blob" do
    it "resolves repository" do
      @actions.blob("gitorious", "master", "app")

      assert_equal ["gitorious"], @resolver.resolved.map(&:name)
    end

    it "returns path, blob, repo, ref and base_tree_url" do
      Repository.any_instance.stubs(:rev_parse).returns(@blob)
      data = @actions.blob("gitorious", "babd120", "app")

      assert_equal({
          :blob => @blob,
          :repository_slug => "gitorious",
          :ref =>  "babd120",
          :path => "app"
        }, data)
    end
  end

  describe "#tree" do
    it "resolves repository" do
      @actions.tree("gitorious", "master", "app")

      assert_equal ["gitorious","gitorious"], @resolver.resolved.map(&:name)
    end

    it "returns tree, repo and ref" do
      Repository.any_instance.stubs(:tree).returns(@tree)
      data = @actions.tree("gitorious", "babd120", "app")
      repo = @resolver.resolved.last

      assert_equal({
          :tree => @tree,
          :repository_slug => "gitorious",
          :ref =>  "babd120",
          :path => "app",
          :readme => nil
        }, data)
    end
  end

  describe "#tree_entry" do
    it "returns tree, repo and ref" do
      Repository.any_instance.stubs(:tree_entry).returns(@tree)
      data = @actions.tree_entry("gitorious", "babd120", "")
      repo = @resolver.resolved.last

      assert_equal({
          :tree => @tree,
          :repository_slug => "gitorious",
          :ref =>  "babd120",
          :path => "",
          :type => :tree
        }, data)
    end

    it "returns blob, repo and ref" do
      Repository.any_instance.stubs(:tree_entry).returns(@blob)
      data = @actions.tree_entry("gitorious", "babd120", "Gemfile")

      assert_equal({
          :blob => @blob,
          :repository_slug => "gitorious",
          :ref =>  "babd120",
          :path => "Gemfile",
          :type => :blob
        }, data)
    end
  end

  describe "#blame" do
    it "resolves repository" do
      @actions.blame("gitorious", "master", "app")

      assert_equal ["gitorious"], @resolver.resolved.map(&:name)
    end

    it "returns blame, repo and ref" do
      Repository.any_instance.stubs(:blame).returns(@blame)
      data = @actions.blame("gitorious", "babd120", "app")

      assert_equal({
          :blame => @blame,
          :repository_slug => "gitorious",
          :ref =>  "babd120",
          :path => "app"
        }, data)
    end
  end

  describe "#history" do
    it "resolves repository" do
      @actions.history("gitorious", "master", "app", 1)

      assert_equal ["gitorious"], @resolver.resolved.map(&:name)
    end

    it "returns commits, repo and ref" do
      Repository.any_instance.stubs(:log).returns([])
      data = @actions.history("gitorious", "babd120", "app", 2)

      assert_equal({
          :commits => [],
          :repository_slug => "gitorious",
          :ref =>  "babd120",
          :path => "app"
        }, data)
    end
  end

  describe "#refs" do
    before do
      @refs = ["refs/stash",
               "refs/tags/v0.2.1",
               "refs/tags/v0.2.0",
               "refs/remotes/origin/master",
               "refs/heads/libgit2",
               "refs/heads/master"].map { |n| OpenStruct.new(:name => n) }
    end

    it "returns repositories, tags and heads" do
      Repository.any_instance.stubs(:refs).returns(@refs)
      Repository.stub_ref("refs/tags/v0.2.0", "a" * 40)
      Repository.stub_ref("refs/tags/v0.2.1", "b" * 40)
      Repository.stub_ref("refs/heads/libgit2", "c" * 40)
      Repository.stub_ref("refs/heads/master", "d" * 40)

      data = @actions.refs("gitorious")

      assert_equal({
          :repository_slug => "gitorious",
          :heads => [["libgit2", "c" * 40], ["master", "d" * 40]],
          :tags => [["v0.2.1", "b" * 40], ["v0.2.0", "a" * 40]]
        }, data)
    end
  end

  describe "#tree_history" do
    before do
      @tree = [{
          :type => :blob,
          :oid => "e90021f89616ddf86855d05337c188408d3b417e",
          :filemode => 33188,
          :name => ".gitmodules",
          :history => [{
            :oid => "906d67b4f3e5de7364ba9b57d174d8998d53ced6",
            :author => { :name => "Christian Johansen",
                         :email => "christian@cjohansen.no" },
            :summary => "Working Dolt server for viewing blobs",
            :date => Time.parse("Mon Sep 10 15:07:39 +0200 2012"),
            :message => ""
          }]
        }, {
          :type => :blob,
          :oid => "c80ee3697054566d1a4247d80be78ec3ddfde295",
          :filemode => 33188,
          :name => "Gemfile",
          :history => [{
            :oid => "26139a3aba4aac8cbf658c0d0ea58b8983e4090b",
            :author => { :name => "Christian Johansen",
                         :email => "christian@cjohansen.no" },
            :summary => "Initial commit",
            :date => Time.parse("Thu Aug 23 11:40:39 +0200 2012"),
            :message => ""
          }]
        }]
    end

    it "returns repository, path, ref and history" do
      Repository.any_instance.stubs(:tree_history).returns(@tree)
      data = @actions.tree_history("gitorious", "master", "", 1)

      assert_equal({
          :repository_slug => "gitorious",
          :ref => "master",
          :path => "",
          :tree => @tree
        }, data)
    end
  end

  describe "repository meta data" do
    it "is returned with other data" do
      resolver = MetaResolver.new
      actions = Dolt::RepoActions.new(resolver)
      data = actions.blob("gitorious", "babd120", "app")

      assert_equal "Meta data is cool", data[:repository_meta]
    end
  end

  describe "#rev_parse_oid" do
    it "resolves ref oid" do
      oid = "a" * 40
      Repository.any_instance.stubs(:rev_parse_oid).returns(oid)
      assert_equal oid, @actions.rev_parse_oid("gitorious", "master")
    end
 end
end
