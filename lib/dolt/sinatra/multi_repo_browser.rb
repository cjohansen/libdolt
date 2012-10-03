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
require "dolt/sinatra/base"
require "dolt/view/single_repository"
require "dolt/view/blob"
require "dolt/view/tree"

module Dolt
  module Sinatra
    class MultiRepoBrowser < Dolt::Sinatra::Base
      include Dolt::View::SingleRepository
      include Dolt::View::Blob
      include Dolt::View::Tree

      aget "/" do
        response["Content-Type"] = "text/html"
        body(renderer.render(:index, { :repositories => actions.repositories }))
      end

      aget "/*/tree/*:*" do
        repo, ref, path = params[:splat]
        tree(repo, ref, path)
      end

      aget "/*/tree/*" do
        force_ref(params[:splat], "tree", "master")
      end

      aget "/*/blob/*:*" do
        repo, ref, path = params[:splat]
        blob(repo, ref, path)
      end

      aget "/*/blob/*" do
        force_ref(params[:splat], "blob", "master")
      end

      aget "/*/raw/*:*" do
        repo, ref, path = params[:splat]
        raw(repo, ref, path)
      end

      aget "/*/raw/*" do
        force_ref(params[:splat], "raw", "master")
      end

      aget "/*/blame/*:*" do
        repo, ref, path = params[:splat]
        blame(repo, ref, path)
      end

      aget "/*/blame/*" do
        force_ref(params[:splat], "blame", "master")
      end

      aget "/*/history/*:*" do
        repo, ref, path = params[:splat]
        history(repo, ref, path, (params[:commit_count] || 20).to_i)
      end

      aget "/*/history/*" do
        force_ref(params[:splat], "history", "master")
      end

      aget "/*/refs" do
        refs(params[:splat].first)
      end

      aget "/*/tree_history/*:*" do
        repo, ref, path = params[:splat]
        tree_history(repo, ref, path)
      end

      private
      def force_ref(args, action, ref)
        redirect(args.shift + "/#{action}/#{ref}:" + args.join)
      end
    end
  end
end
