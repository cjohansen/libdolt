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
require "libdolt/view/markup"
require "libdolt/view/syntax_highlight"

module StubHighlighter
  def highlight(path, code, opt = {})
    return "##[#{opt[:lexer]}]#{code}##"
  end
end

describe Dolt::View::Markup do
  include Dolt::View::Markup

  describe "#render_markup" do
    include Dolt::View::SyntaxHighlight

    it "wraps markup in .gts-markup" do
      html = render_markup("file.md", "# Hey")
      assert_match "<div class=\"gts-markup\">", html
    end

    it "renders multi-line code blocks with syntax highlighting" do
      html = render_markup("file.md", <<-MD)
```cl
(s-trim-left "trim ") ;; => "trim "
(s-trim-left " this") ;; => "this"
```
      MD

      assert_match "<pre class=\"common-lisp prettyprint\">", html
    end

    it "highlights multiple separate multi-line code blocks" do
      html = render_markup("file.md", <<-MD)
# # This stuff

```cl
(s-trim-left "trim ") ;; => "trim "
(s-trim-left " this") ;; => "this"
```

# And this stuff

```cl
(s-trim-left "trim ") ;; => "trim "
(s-trim-left " this") ;; => "this"
```
      MD

      assert_equal 2, html.scan(/common-lisp/).length
    end
  end
end
