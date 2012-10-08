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
require "libdolt/view/object"

describe Dolt::View::Object do
  include Dolt::View::Object

  describe "#object_icon_class" do
    it "returns blob icon type" do
      assert_equal "icon-file", object_icon_class({ :type => :blob })
    end

    it "returns tree icon type" do
      assert_equal "icon-folder-close", object_icon_class({ :type => :tree })
    end

    it "returns submodule icon type" do
      assert_equal "icon-hdd", object_icon_class({ :type => :submodule })
    end
  end
end
