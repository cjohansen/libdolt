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
require "libdolt/view/commit"

describe Dolt::View::Commit do
  include Dolt::Html
  include Dolt::View::Commit

  describe "#commit_oid" do
    it "returns the first seven characters" do
      oid = "38b06b3f65a9c84ac860bf0ce0a69e43a23bc765"
      assert_equal "38b06b3", commit_oid(oid)
    end
  end
end
