# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
require "json"
require "time"
require "cgi"

module Dolt
  class ControllerActions
    def initialize(router, lookup, renderer)
      @router = router
      @lookup = lookup
      @renderer = renderer
    end

    def redirect(url, status = 302)
      body = "You are being <a href=\"#{url}\">redirected to #{url}</a>"
      [status, { "Location" => url }, [body]]
    end

    def render_error(error, repo, ref, data = {})
      $stderr.puts("#{error.class.to_s}: #{error.message}")
      $stderr.puts(error.backtrace)

      if error.class.to_s == "Rugged::ReferenceError" && ref == "HEAD"
        template = "empty"
        return [200, headers, [renderer.render(template, {
                :repository => repo,
                :ref => ref
              }.merge(data))]]
      end

      if error.class.to_s == "Rugged::ReferenceError"
        template = "non_existent"
        return [404, headers, [renderer.render(template, {
                :repository => repo,
                :ref => ref,
                :error => error
              }.merge(data))]]
      end

      response = error.class.to_s == "Rugged::IndexerError" ? 404 : 500
      template = response.to_s.to_sym
      [response, headers, [renderer.render(template, {
              :error => error,
              :repository_slug => repo,
              :ref => ref
            }.merge(data))]]
    rescue Exception => err
      err_backtrace = err.backtrace.map { |s| "<li>#{s}</li>" }
      error_backtrace = error.backtrace.map { |s| "<li>#{s}</li>" }

      [500, headers, [<<-HTML]]
        <h1>Fatal Dolt Error</h1>
        <p>
          Dolt encountered an exception, and additionally
          triggered another exception trying to render the error.
        </p>
        <p>Tried to render the #{template} template with the following data:</p>
        <dl>
          <dt>Repository</dt>
          <dd>#{repo}</dd>
          <dt>Ref</dt>
          <dd>#{ref}</dd>
        </dl>
        <h2>Error: #{err.class} #{err.message}</h2>
        <ul>#{err_backtrace.join()}</ul>
        <h2>Original error: #{error.class} #{error.message}</h2>
        <ul>#{error_backtrace.join()}</ul>
        HTML
    end

    def raw(repo, ref, path, custom_data = {})
      if oid = lookup_ref_oid(repo, ref)
        return redirect(router.raw_url(repo, oid, path), 307)
      end

      blob(repo, ref, path, custom_data, {
          :template => :raw,
          :content_type => "text/plain",
          :template_options => { :layout => nil }
        })
    end

    def blob(repo, ref, path, custom_data = {}, options = { :template => :blob })
      if oid = lookup_ref_oid(repo, ref)
        return redirect(router.blob_url(repo, oid, path), 307)
      end

      data = (custom_data || {}).merge(lookup.blob(repo, u(ref), path))
      blob = data[:blob]
      return redirect(router.tree_url(repo, ref, path)) if blob.class.to_s !~ /\bBlob/

      tpl_options = options[:template_options] || {}
      [200, headers(options.merge(:ref => ref)), [
          renderer.render(options[:template], data, tpl_options)
        ]]
    end

    def tree(repo, ref, path, custom_data = {})
      if oid = lookup_ref_oid(repo, ref)
        return redirect(router.tree_url(repo, oid, path), 307)
      end

      data = (custom_data || {}).merge(lookup.tree(repo, u(ref), path))
      tree = data[:tree]
      return redirect(router.blob_url(repo, ref, path)) if tree.class.to_s !~ /\bTree/
      [200, headers(:ref => ref), [renderer.render(:tree, data)]]
    end

    def tree_entry(repo, ref, path, custom_data = {})
      if oid = lookup_ref_oid(repo, ref)
        return redirect(router.tree_entry_url(repo, oid, path), 307)
      end

      data = (custom_data || {}).merge(lookup.tree_entry(repo, u(ref), path))
      body = renderer.render(data.key?(:tree) ? :tree : :blob, data)
      [200, headers(:ref => ref), [body]]
    end

    def blame(repo, ref, path, custom_data = {})
      if oid = lookup_ref_oid(repo, ref)
        return redirect(router.blame_url(repo, oid, path), 307)
      end

      data = (custom_data || {}).merge(lookup.blame(repo, u(ref), path))
      [200, headers(:ref => ref), [renderer.render(:blame, data)]]
    end

    def history(repo, ref, path, count, custom_data = {})
      if oid = lookup_ref_oid(repo, ref)
        return redirect(router.history_url(repo, oid, path), 307)
      end

      data = (custom_data || {}).merge(lookup.history(repo, u(ref), path, count))
      [200, headers(:ref => ref), [renderer.render(:commits, data)]]
    end

    def refs(repo, custom_data = {})
      data = (custom_data || {}).merge(lookup.refs(repo))
      [200, headers(:content_type => "application/json"), [
          renderer.render(:refs, data, :layout => nil)
        ]]
    end

    def tree_history(repo, ref, path, count = 1, custom_data = {})
      if oid = lookup_ref_oid(repo, ref)
        return redirect(router.tree_history_url(repo, oid, path), 307)
      end

      data = (custom_data || {}).merge(lookup.tree_history(repo, u(ref), path, count))
      [200, headers(:content_type => "application/json", :ref => ref), [
          renderer.render(:tree_history, data, :layout => nil)
        ]]
    end

    def resolve_repository(repo)
      @cache ||= {}
      @cache[repo] ||= lookup.resolve_repository(repo)
    end

    def lookup_ref_oid(repo, ref)
      return if !router.respond_to?(:redirect_refs?) || !router.redirect_refs? || ref.length == 40
      lookup.rev_parse_oid(repo, ref)
    end

    private
    attr_reader :router, :lookup, :renderer

    def u(str)
      # Temporarily swap the + out with a magic byte, so
      # filenames/branches with +'s won't get unescaped to a space
      CGI.unescape(str.gsub("+", "\001")).gsub("\001", '+')
    end

    def headers(options = {})
      default_ct = "text/html; charset=utf-8"
      year = 60*60*24*365

      {
        "Content-Type" => options[:content_type] || default_ct,
        "X-UA-Compatible" => "IE=edge"
      }.merge(!options[:ref] || options[:ref].length != 40 ? {} : {
          "Cache-Control" => "max-age=315360000, public",
          "Expires" => (Time.now + year).httpdate
        })
    end
  end
end
