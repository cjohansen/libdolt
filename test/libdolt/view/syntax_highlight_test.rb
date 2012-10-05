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
require "libdolt/view/blob"
require "libdolt/view/syntax_highlight"

describe Dolt::View::Blob do
  include Dolt::View::Blob
  include Dolt::View::SyntaxHighlight

  describe "#highlight" do
    it "highlights a Ruby file" do
      html = highlight("file.rb", "class File\n  attr_reader :path\nend")

      assert_match "<span class=\"k\">class</span>", html
      assert_match "<span class=\"nc\">File</span>", html
    end

    it "highlights a YAML file" do
      html = highlight("file.yml", "something:\n  is: true")

      assert_match "<span class=\"l-Scalar-Plain\">something</span>", html
      assert_match "<span class=\"p-Indicator\">:", html
    end

    it "highlights an .htm file" do
      html = highlight("file.htm", "<h1>Hey</h1>")

      assert_match "<span class=\"nt\">&lt;h1&gt;</span>", html
      assert_match "Hey<span class=\"nt\">&lt;/h1&gt;</span>", html
    end

    it "highlights file with custom suffix" do
      Dolt::View::SyntaxHighlight.add_lexer_alias("derp", "rb")
      html = highlight("file.derp", "class File")

      assert_match "<span class=\"k\">class</span>", html
      assert_match "<span class=\"nc\">File</span>", html
    end

    it "skips highlighting if lexer is missing" do
      html = highlight("file.trololol", "Yeah yeah yeah")

      assert_equal "Yeah yeah yeah", html
    end
  end

  describe "#format_blob" do
    it "highlights a Ruby file with line nums" do
      html = format_blob("file.rb", "class File\n  attr_reader :path\nend")

      assert_match "<li class=\"L1\">", html
      assert_match "<span class=\"k\">class</span>", html
    end

    it "includes lexer as class name" do
      html = format_blob("file.rb", "class File\n  attr_reader :path\nend")

      assert_match "rb", html
    end
  end

  describe "#lexer" do
    it "uses known suffix" do
      assert_equal "rb", lexer("file.rb")
    end

    it "uses registered suffix" do
      Dolt::View::SyntaxHighlight.add_lexer_alias("blarg", "blarg")
      assert_equal "blarg", lexer("file.blarg")
    end

    it "uses registered lexer" do
      Dolt::View::SyntaxHighlight.add_lexer_alias("bg", "blarg")
      assert_equal "blarg", lexer("file.bg")
    end

    it "uses known shebang" do
      assert_equal "rb", lexer("some-binary", "#!/usr/bin/env ruby\n")
    end

    it "uses registered shebang" do
      Dolt::View::SyntaxHighlight.add_lexer_shebang(/\bnode\b/, "js")
      assert_equal "js", lexer("some-binary", "#!/usr/bin/env node\n")
    end

    it "uses filename for unknown lexer" do
      assert_equal "some-binary", lexer("some-binary", "class Person\nend")
    end
  end
end
