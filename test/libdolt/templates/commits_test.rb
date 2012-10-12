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

describe "commits template" do
  include Dolt::ViewTest

  def commit(num)
    { :oid => num + ("0" * 39),
      :summary => "Commit ##{num}",
      :author => @author,
      :date => Time.now }
  end

  before do
    @repo = "the-dolt"
    @author = {
      :name => "Christian Johansen",
      :email => "christian@gitorious.com"
    }
    @commit1 = commit("1")
    @commit2 = commit("2")
    @commit3 = commit("3")
  end

  def render(path, commits, options = {})
    renderer = prepare_renderer(options)
    renderer.render(:commits, {
                      :commits => commits,
                      :repository_slug => @repo,
                      :ref => options[:ref] || "master",
                      :path => path
                    })
  end

  it "renders history" do
    markup = render("app/models/repository.rb", [@commit1, @commit2, @commit3])

    assert_match /Commit #1/, markup
    assert_match /Commit #2/, markup
    assert_match /Commit #3/, markup
  end
end
