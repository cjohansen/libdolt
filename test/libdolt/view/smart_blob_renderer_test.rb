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
require "libdolt/view/smart_blob_renderer"

describe Dolt::View::SmartBlobRenderer do
  include Dolt::View::Blob
  include Dolt::View::SmartBlobRenderer

  describe "#format_text_blob" do
    it "highlights a Ruby file" do
      html = format_text_blob("file.rb", "class File\n  attr_reader :path\nend")

      assert_match "<span class=\"k\">class</span>", html
      assert_match "<span class=\"nc\">File</span>", html
    end

    it "wraps markup in .gts-markup" do
      html = render_markup("file.md", "# Hey")
      assert_match "<div class=\"gts-markup\">", html
    end
  end
end
