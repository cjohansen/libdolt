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
require "libdolt/view/multi_repository"

describe Dolt::View::MultiRepository do
  include Dolt::Html
  include Dolt::View::MultiRepository

  describe "#repo_url" do
    it "returns url prefixed with repository" do
      assert_equal "/gitorious/some/%C3%F5/url", repo_url("gitorious", "/some/\xC3\xF5/url")
    end

    it "returns url prefixed with repository name containing slashes" do
      url = repo_url("gitorious/mainline", "/some/url")
      assert_equal "/gitorious/mainline/some/url", url
    end
  end
end
