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
require "libdolt/view/multi_repository"
require "libdolt/view/urls"

describe Dolt::View::Urls do
  include Dolt::View::Urls

  describe "single repo mode" do
    include Dolt::View::SingleRepository

    it "returns blame url" do
      url = blame_url("myrepo", "master", "some/path")
      assert_equal "/blame/master:some/path", url
    end

    it "returns history url" do
      url = history_url("myrepo", "master", "some/path")
      assert_equal "/history/master:some/path", url
    end

    it "returns raw url" do
      url = raw_url("myrepo", "master", "some/path")
      assert_equal "/raw/master:some/path", url
    end
  end

  describe "multi repo mode" do
    include Dolt::View::MultiRepository

    it "returns blame url" do
      url = blame_url("myrepo", "master", "some/path")
      assert_equal "/myrepo/blame/master:some/path", url
    end

    it "returns history url" do
      url = history_url("myrepo", "master", "some/path")
      assert_equal "/myrepo/history/master:some/path", url
    end

    it "returns raw url" do
      url = raw_url("myrepo", "master", "some/path")
      assert_equal "/myrepo/raw/master:some/path", url
    end
  end
end
