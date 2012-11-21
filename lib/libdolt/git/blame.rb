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
require "tzinfo"

module Dolt
  module Git
    class Blame
      attr_reader :chunks

      def initialize(chunks)
        @chunks = chunks
      end

      def self.parse_porcelain(output)
        self.new(Dolt::Git::Blame::PorcelainParser.new(output).parse)
      end

      class PorcelainParser
        def initialize(output)
          @output = output
          @commits = {}
        end

        def parse
          lines = @output.split("\n")
          chunks = []

          while lines.length > 0
            chunk = extract_header(lines)
            affected_lines = extract_lines(lines, chunk[:num_lines])

            if chunks.last && chunk[:oid] == chunks.last[:oid]
              chunks.last[:lines].concat(affected_lines)
            else
              chunk[:lines] = affected_lines
              chunks << chunk
            end
          end

          chunks
        end

        def is_header?(line)
          line =~ /^[0-9a-f]{40} \d+ \d+ \d+$/
        end

        def extract_header(lines)
          header = lines.shift
          pieces = header.scan(/^([0-9a-f]{40}) (\d+) (\d+) (\d+)$/).first
          header = { :oid => pieces.first, :num_lines => pieces[3].to_i }

          if lines.first =~ /^author/
            header[:author] = extract_hash(lines, :author)
            header[:committer] = extract_hash(lines, :committer)
            header[:summary] = extract(lines, "summary")
            throwaway = lines.shift until throwaway =~ /^filename/
            @commits[header[:oid]] = header
          else
            header[:author] = @commits[header[:oid]][:author]
            header[:committer] = @commits[header[:oid]][:committer]
            header[:summary] = @commits[header[:oid]][:summary]
          end

          header
        end

        def extract_lines(lines, num)
          extracted = []

          num.times do
            if extracted.length > 0
              line = lines.shift # Header for next line
            end

            content = lines.shift # Actual content
            extracted.push(content[1..content.length]) # 8 spaces padding
          end

          extracted
        end

        def extract_hash(lines, type)
          {
            :name => extract(lines, "#{type}"),
            :mail => extract(lines, "#{type}-mail").gsub(/[<>]/, ""),
            :time => (Time.at(extract(lines, "#{type}-time").to_i).utc +
                      Time.zone_offset(extract(lines, "#{type}-tz")))
          }
        end

        def extract(lines, thing)
          lines.shift.split("#{thing} ")[1]
        end
      end
    end
  end
end
