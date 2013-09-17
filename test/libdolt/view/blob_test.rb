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
require "libdolt/view/blob"
require "libdolt/view/urls"

describe Dolt::View::Blob do
  include Dolt::View::Blob
  include Dolt::View::Urls
  include Dolt::View::SingleRepository

  describe "#multiline" do
    it "adds line number markup to code" do
      html = multiline("A few\nLines\n    Here")

      assert_match "<pre", html
      assert_match "<ol class=\"linenums", html
      assert_match "<li class=\"L1\"><span class=\"line\">A few</span></li>", html
      assert_match "<li class=\"L2\"><span class=\"line\">Lines</span></li>", html
      assert_match "<li class=\"L3\"><span class=\"line\">    Here</span></li>", html
    end

    it "adds custom class name" do
      html = multiline("A few\nLines\n    Here", :class_names => ["ruby"])

      assert_match "prettyprint", html
      assert_match "linenums", html
      assert_match "ruby", html
    end
  end

  describe "#format_text_blob" do
    it "escapes brackets" do
      html = format_text_blob("file.txt", "<hey>")
      assert_match /&lt;hey&gt;/, html
    end
  end

  describe "#format_binary_blob" do
    it "renders link to binary blob" do
      content = "GIF89aK\000 \000\367\000\000\266\270\274\335\336\337\214"
      html = format_binary_blob("some/file.gif", content, "gitorious", "master")
      assert_match /<a href="\/raw\/master:some\/file.gif"/, html
      assert_match "Download file.gif", html
    end
  end

  describe "#format_blob" do
    it "renders link to binary blob" do
      content = "GIF89aK\000 \000\367\000\000\266\270\274\335\336\337\214"
      html = format_blob("file.gif", content, "gitorious", "master")
      assert_match "Download file.gif", html
    end

    it "renders text blob" do
      html = format_blob("file.txt", "<hey>")
      assert_match /&lt;hey&gt;/, html
    end
  end

  describe "safe_blob_text" do
    it "returns blob's text with all invalid characters (for string's encoding) replaced with �" do
      repository = Dolt::Git::Repository.new(Dolt.fixture_repo_path)
      blob = repository.blob('master', 'bad-utf.txt')

      assert_equal "żółć & �.", safe_blob_text(blob)
    end
  end
end
