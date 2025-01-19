require "log"
require "./builder"
require "./markup"

module Poor::Markdown

	def self.parse(io : IO, builder : Poor::Builder | Poor::Stream)
		builder.start(Base.new)
		parse_blocks(io, builder) do |block|
			builder.add(block.build)
		end
		builder.finish
	end

	private def self.parse_blocks(io : IO, b : Poor::Builder | Poor::Stream)
		parents = Deque(MarkdownBlock).new
		io.each_line do |line|
			parents_iter = parents.each_with_index
			closing = nil
			until (elem = parents_iter.next).is_a?(Iterator::Stop) || closing
				block, idx = elem
				if (stripped = continues_block?(line, block.type)) && !starts_block?(line)
					Log.debug { "Line '#{line}' continues #{block}" }
					line = stripped
				else
					Log.debug { "Closing #{block}" }
					closing = idx
				end
			end

			closing.try do |idx|
				last = nil
				(parents.size - idx).times do
					last = parents.pop
				end
				if parents.empty? && last
					yield last
				end
			end

			new_block = starts_block?(line)
			insert_line = new_block.nil?
			if new_block.nil? && parents.empty?
				new_block = MarkdownBlock.new(Paragraph.new)
				insert_line = true
			end
			if new_block
				Log.debug { "Line '#{line}' starts #{new_block.type}" }
				Log.debug { "Adding #{new_block} to parents" }
				parents.last?.try { |last| last.children << new_block }
				parents.push new_block
			end

			Log.debug { "Pushing '#{line}' to #{parents.last}" }
			parents.last.content << line if insert_line
		end
		unless parents.empty?
			yield parents.first
		end
	end

	private def self.continues_block?(line, block : Markup) : String?
		case block
		when Paragraph
			unless line.empty?
				line
			end
		end
	end

	private def self.starts_block?(line : String) : MarkdownBlock?
		if line.starts_with?('#')
			count = line.each_char.take_while{ |c| c == '#' }.size
			if line.char_at(count) == ' '
				MarkdownBlock.new(Bold.new(line[count+1..]))
			end
		end
	end

	private def self.parse_inline(line : String)
	end
end

private class MarkdownBlock
	property type : Markup
	property children : Array(MarkdownBlock) = [] of MarkdownBlock
	property content : Array(String) = [] of String

	def initialize(@type)
	end

	def build : Markup
		result = @type
		children.each do |child|
			built = child.build
			result.children << built
		end
		unless content.empty?
			result.children << PlainText.new(content.join(" "))
		end
		result
	end
end
