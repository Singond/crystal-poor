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
		lineno = 0
		io.each_line do |line|
			Log.debug { "At line #{lineno += 1}: '#{line}'" }
			parents_iter = parents.each_with_index
			closing = nil
			until (elem = parents_iter.next).is_a?(Iterator::Stop) || closing
				block, idx = elem
				cont, line = continues_block?(line, block) if line
				if cont
					Log.debug { "Line continues #{block}" }
				else
					Log.debug { "Line closes #{block}" }
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

			next if line.nil? || line.empty?

			new_block = starts_block?(line)
			insert_line = new_block.nil?
			if new_block.nil? && parents.empty?
				new_block = MarkdownBlock.new(Paragraph.new)
				insert_line = true
			end
			if new_block
				Log.debug { "Line starts #{new_block.type}" }
				parents.last?.try { |last| last.children << new_block }
				parents.push new_block
			end

			if insert_line
				Log.debug { "Pushing line to #{parents.last}" }
				parents.last.content << line
			end
		end
		unless parents.empty?
			yield parents.first
		end
	end

	private def self.continues_block?(line, block : MarkdownBlock) : {Bool, String?}
		case block.type
		when Paragraph
			if level = setext_underline?(line)
				Log.debug { "Line is a setext underline, changing block type" }
				block.type = Bold.new  # TODO: Change to heading
				return {false, nil}
			elsif starts_block?(line)
				return {false, line}
			end
			# TODO: Remove 0-3 starting whitespace
			# chars.skip_while { |c, i| c == ' ' && i <=3 }
			# if (c = chars.next) == '=' || c == '-'
			# 	chars.skip_while { |more| more == c }
			unless line.empty?
				return {true, line}
			end
		end
		{false, line}
	end

	private def self.starts_block?(line : String) : MarkdownBlock?
		if line.starts_with?('#')
			count = line.each_char.take_while{ |c| c == '#' }.size
			if line.char_at(count) == ' '
				MarkdownBlock.new(Bold.new(line[count+1..]))
			end
		end
	end

	private def self.setext_underline?(str : String) : Int8?
		chars = str.each_char
		spaces = 0
		while (c = chars.next) == ' ' && spaces <= 3
			spaces += 1
		end
		level = case c
		when '=' then 1_i8
		when '-' then 2_i8
		else nil
		end
		if level && level > 0
			while chars.next == c
				# skip
			end
			if c.is_a? Char && c.whitespace?
				# Allow whitespace after
				while (c = chars.next).is_a? Char && c.whitespace?
					# skip
				end
			end
			# If there is nothing more, the line is an underline
			if chars.next.is_a? Iterator::Stop
				return level
			end
		end
		nil
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

	def to_s(io : IO)
		io << "MarkdownBlock{"
		io << type
		io << "}"
	end
end
