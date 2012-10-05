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
require "libdolt/view/blame"
require "ostruct"

describe Dolt::View::Blame do
  include Dolt::Html
  include Dolt::View::Blame

  before do
    chunks = [{ :oid => "0000001", :lines => ["1", "2", "3"] },
              { :oid => "0000002", :lines => ["4", "5"] }]
    @blame = OpenStruct.new({ :chunks => chunks })
  end

  describe "#blame_annotations" do
    it "returns array of same length as total number of lines" do
      annotations = blame_annotations(@blame)

      assert_equal 5, annotations.length
    end

    it "stores annotation for first occurrence" do
      annotations = blame_annotations(@blame)

      assert_equal "0000001", annotations.first[:oid]
    end

    it "stores nil for consecutive entries in same chunk" do
      annotations = blame_annotations(@blame)

      assert_nil annotations[1]
      assert_nil annotations[2]
      refute_nil annotations[3]
      assert_nil annotations[4]
    end
  end

  describe "#blame_lines" do
    it "returns array of lines" do
      assert_equal 5, blame_lines("file.rb", @blame).length
    end

    it "does not modify lines" do
      assert_equal "1", blame_lines("file.rb", @blame).first
    end
  end

  describe "#blame_lines with #highlight" do
    def highlight(path, code)
      "{" + code.split("\n").map { |l| "#{path}:#{l}" }.join("\n") + "}"
    end

    it "highlights code before splitting" do
      lines = blame_lines("file.rb", @blame)

      assert_equal "{file.rb:1", lines.first
      assert_equal "file.rb:2", lines[1]
      assert_equal "file.rb:5}", lines.last
    end
  end

  describe "#blame_annotation_cell" do
    before do
      @oid = "1234567890" * 4

      @committer = {
        :name => "Christian Johansen",
        :time => Time.utc(2012, 1, 1, 12)
      }
    end

    it "returns table cell with annotated class" do
      html = blame_annotation_cell({ :committer => @committer, :oid => @oid })

      assert_match /gts-blame-annotation/, html
      assert_match /gts-annotated/, html
      assert_match /Christian Johansen/, html
    end

    it "includes the commit oid" do
      html = blame_annotation_cell({ :committer => @committer, :oid => @oid })

      assert_match /gts-sha/, html
      assert_match /1234567/, html
      refute_match /890/, html
    end

    it "includes the commit date" do
      html = blame_annotation_cell({ :committer => @committer, :oid => @oid })

      assert_match /2012-01-01/, html
    end
  end

  describe "#blame_code_cell" do
    it "returns table cell with code element" do
      html = blame_code_cell("var a = 42;")

      assert_equal 1, select(html, "td").length
      assert_match /gts-code/, html
      assert_equal 1, select(html, "code").length
      assert_match /a = 42/, html
    end
  end
end
