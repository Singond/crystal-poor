require "log"
require "./builder"
require "./markup"

# Basic Markdown parser.
module Poor::Markdown

	# Parses the content of *io* and adds each top-level block
	# represented as `Markup` to *builder*.
	def self.parse(io : IO, builder : Poor::Builder | Poor::Stream)
		builder.start(Base.new)
		each_top_level_block(io) do |block|
			builder.add(block.build)
		end
		builder.finish
	end

	# Parses the content of *io* and yields each top-level block
	# as `Markup`.
	def self.each_top_level_block(io : IO)
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

	# Determines whether *str* is a setext heading underline,
	# that is a line, optionally indented by up to three spaces,
	# consisting entirely of '=' or entirely of '-' characters.
	def self.setext_underline?(str : String) : Int8?
		count, type, _, rest = self.repeated_char?(str, {'=', '-'}, max_indent: 3)
		if count > 0
			level = case type
			when '=' then 1_i8
			when '-' then 2_i8
			else 0_i8
			end
			# Allow whitespace after
			if level > 0 && rest.blank?
				return level
			end
		end
		nil
	end

	# Determines whether *str* starts with a repetition of a single character
	# from *chars*, optionally preceded by spaces.
	#
	# The first character in the repetition can be any of the given *chars*,
	# but all the other characters must be the same as the first one.
	# Maximum number of spaces allowed at the beginning of the string
	# can be changed by the `max_indent` argument. The default is 0.
	#
	# Returns a tuple containing the number of repetitions of the character,
	# the character itself, the number of spaces at the beginning
	# and the remaining part of *str* after the repetition.
	private def self.repeated_char?(str : String, characters, max_indent = 0)
		chars = str.each_char

		# Skip indent
		indent = 0
		while (c = chars.next) == ' ' && indent < max_indent
			indent += 1
		end

		# Count the repeated characters
		count = 1
		if c.in? characters
			while chars.next == c
				count += 1
			end
		else
			c = nil
		end

		{count, c, indent, str[indent+count..]}
	end

	private def self.parse_inline(line : String)
	end
end

# A block element in a Markdown document.
private class MarkdownBlock
	property type : Markup
	property children : Array(MarkdownBlock) = [] of MarkdownBlock
	property content : Array(String) = [] of String

	def initialize(@type)
	end

	# Converts the tree of Markdown elements under `self` into `Markup`.
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
