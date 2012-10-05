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
require "libdolt/view/binary_blob_embedder"

describe Dolt::View::BinaryBlobEmbedder do
  include Dolt::View::Blob
  include Dolt::View::BinaryBlobEmbedder
  include Dolt::View::SingleRepository

  it "renders image tag to view gif" do
    html = format_binary_blob("file.gif", "...", "gitorious", "master")

    assert_match /<img/, html
    assert_match /src="\/raw\/master:file.gif"/, html
  end

  it "renders image tag to view png" do
    html = format_binary_blob("file.png", "...", "gitorious", "master")
    assert_match /src="\/raw\/master:file.png"/, html
  end

  it "renders image tag to view jpg" do
    html = format_binary_blob("file.jpg", "...", "gitorious", "master")
    assert_match /src="\/raw\/master:file.jpg"/, html
  end

  it "renders image tag to view jpeg" do
    html = format_binary_blob("file.jpeg", "...", "gitorious", "master")
    assert_match /src="\/raw\/master:file.jpeg"/, html
  end
end
