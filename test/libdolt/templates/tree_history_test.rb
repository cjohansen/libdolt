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
require "json"

describe "tree_history template" do
  include Dolt::ViewTest

  before do
    @repo = "the-dolt"
    @renderer = prepare_renderer
    @tree = [{
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

    @tree_array = [{
      "type" => "blob",
      "oid" => "e90021f89616ddf86855d05337c188408d3b417e",
      "filemode" => 33188,
      "name" => ".gitmodules",
      "history" => [{
        "oid" => "906d67b4f3e5de7364ba9b57d174d8998d53ced6",
        "author" => { "name" => "Christian Johansen",
                     "email" => "christian@cjohansen.no" },
        "summary" => "Working Moron server for viewing blobs",
        "date" => "2012-09-10T15:07:39+02:00",
        "message" => ""
      }]
    }, {
      "type" => "blob",
      "oid" => "c80ee3697054566d1a4247d80be78ec3ddfde295",
      "filemode" => 33188,
      "name" => "Gemfile",
      "history" => [{
        "oid" => "26139a3aba4aac8cbf658c0d0ea58b8983e4090b",
        "author" => { "name" => "Christian Johansen",
                     "email" => "christian@cjohansen.no" },
        "summary" => "Initial commit",
        "date" => "2012-08-23T11:40:39+02:00",
        "message" => ""
      }]
    }]
  end

  it "renders JSON" do
    data = { "tree" => @tree, "repository_slug" => @repo, "ref" => "master", "path" => "" }
    json = @renderer.render(:tree_history, data)

    assert_equal @tree_array, JSON.parse(json)
  end
end
