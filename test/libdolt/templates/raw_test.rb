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

class Blob
  attr_reader :content
  def initialize(content); @content = content; end
end

describe "raw template" do
  include Dolt::ViewTest

  before do
    @repo = "the-dolt"
  end

  it "renders raw contents" do
    renderer = prepare_renderer
    html = renderer.render(:raw, { :blob => Blob.new("Something something") })

    assert_equal "Something something\n", html
  end
end
