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
require "libdolt/view/tab_width"

describe Dolt::View::TabWidth do
  include Dolt::View::Blob
  include Dolt::View::TabWidth

  describe "#format_whitespace" do
    it "limits width of whitespace" do
      def self.tab_width; 4; end
      html = format_whitespace("class File\n\tattr_reader :path\nend")

      assert_match(/    attr_reader/, html)
    end

    it "uses wide tabs in formatted blobs" do
      def self.tab_width; 12; end
      html = format_text_blob("file.rb", "class File\n\tattr_reader :path\nend")

      assert_match(/            attr_reader/, html)
    end
  end
end
