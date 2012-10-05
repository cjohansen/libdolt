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

class Blame
  attr_reader :chunks
  def initialize(chunks); @chunks = chunks; end
end

describe "blame template" do
  include Dolt::ViewTest

  before do
    @repo = "the-dolt"
    @committer = {
      :name => "Christian Johansen",
      :mail => "christian@cjohansen.no",
      :time => Time.now
    }
  end

  def render(path, blame, options = {})
    renderer = prepare_renderer(options)
    renderer.render(:blame, {
                      :blame => blame,
                      :repository => @repo,
                      :ref => options[:ref] || "master",
                      :path => path
                    })
  end

  it "renders blame" do
    blob = Blame.new([{ :oid => "0123456", :committer => @committer, :lines => [] }])
    markup = render("app/models/repository.rb", blob)

    assert_match /<table class="gts-code-listing">/, markup
  end
end
