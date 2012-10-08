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
require "libdolt/view/breadcrumb"

describe Dolt::View::Breadcrumb do
  include Dolt::Html
  include Dolt::View::SingleRepository
  include Dolt::View::Urls
  include Dolt::View::Breadcrumb

  it "renders li element for root" do
    html = breadcrumb("myrepo", "master", "path.txt")

    assert_equal 1, select(html, "a").length
    assert_match /icon-file/, select(html, "li").first
  end

  it "renders li element for file" do
    html = breadcrumb("myrepo", "master", "path.txt")

    assert_match /path.txt/, select(html, "li").last
  end

  it "renders links to accumulated paths" do
    html = breadcrumb("myrepo", "master", "some/nested/path.txt")

    links = select(html, "a")
    assert_match /\"\/tree\/master:some"/, links[1]
    assert_match /\"\/tree\/master:some\/nested"/, links[2]
  end
end
