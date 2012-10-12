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
require "libdolt/view"

class Tree
  attr_reader :entries
  def initialize(entries); @entries = entries; end
end

describe "tree template" do
  include Dolt::ViewTest

  before do
    @repo = "the-dolt"
  end

  def render(path, tree, options = {})
    renderer = prepare_renderer(options)
    renderer.render(:tree, {
                      :tree => tree,
                      :repository_slug => @repo,
                      :ref => options[:ref] || "master",
                      :path => path
                    })
  end

  it "renders empty tree" do
    tree = Tree.new([])
    markup = render("app/models", tree)

    assert_match /<table class="table table-striped gts-tree-explorer"/, markup
    assert_match /data-gts-tree-history="/, markup
  end

  it "renders context for non-empty tree" do
    tree = Tree.new([
      { :type => :tree, :name => "lib" },
      { :type => :submodule, :name => "ui", :url => "git://git.git" },
      { :type => :blob, :name => "file.txt" }
    ])

    markup = render("app/models", tree)

    assert_match /icon-folder-open/, markup
    assert_match /tree\/master:app"/, markup
  end
end
