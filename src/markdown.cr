require "log"
require "./builder"
require "./markup"
require "./utils"

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
		self.each_block(io) do |block, parents|
			if parents.empty? && block
				yield block
			end
		end
	end

	# Parses the content of *io* and yields each block as `Markup`
	# as it is closed, together with its parents.
	private def self.each_block(io : IO)
		parents = Deque(MarkdownBlock).new
		lineno = 0
		io.each_line do |line|
			Log.debug { "At line #{lineno += 1}: '#{line}'" }

			# Check if parents continue into this line
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

			# Close parents which do not continue into this line
			closing.try do |idx|
				(parents.size - idx).times do
					yield parents.pop, parents
				end
			end

			# If there is no more text, go to next line
			next if line.nil? || line.empty?

			# See if the line starts a new block and add it
			new_block = starts_block?(line)
			if new_block
				Log.debug { "Line starts #{new_block}" }
			end
			insert_line = new_block.nil?
			if (p = parents.last?) && p.type.is_a? MarkdownList && !(new_block.try &.type.is_a? MarkdownListItem)
				Log.debug { "Closing parent list, because new block is not a list item" }
				yield parents.pop, parents
			end
			if new_block.nil?
				if parents.empty?
					Log.debug { "Starting paragraph, because parent is not a paragraph" }
					new_block = MarkdownBlock.new(MarkdownParagraph.new)
					insert_line = true
				end
			elsif (type = new_block.type).is_a? MarkdownListItem
				unless (p = parents.last?) && p.type.is_a? MarkdownList
					Log.debug { "Inserting list, because new block is a list item" }
					parents.push MarkdownBlock.new(MarkdownList.new(type))
				end
			end
			if new_block
				parents.last?.try { |last| last.children << new_block }
				parents.push new_block
			end
			Log.trace { "Parent blocks: #{self.parents_to_s(parents)}" }

			# Insert the line into the deepest parent
			if insert_line
				Log.debug { "Pushing line to #{parents.last}" }
				parents.last.content << line
			end
		end
		# Yield the last block
		unless parents.empty?
			yield parents.first, [] of MarkdownBlock
		end
	end

	private def self.continues_block?(line, block : MarkdownBlock) : {Bool, String?}
		case type = block.type
		when MarkdownParagraph
			if level = setext_underline?(line)
				Log.debug { "Line is a setext underline, changing block type" }
				block.type = MarkdownHeading.new(level)
				return {false, nil}
			elsif starts_block?(line)
				return {false, line}
			end
			unless line.empty?
				return {true, line}
			end
		when MarkdownFence
			if (fence = code_fence?(line)) && fence.ends?(type)
				return {false, nil}
			end
			return {true, line}
		when MarkdownList
			return {true, line}
		when MarkdownListItem
			if line.try &.starts_with_spaces?(type.total_width)
				return {true, line[type.total_width..]?}
			end
			return {false, line}
		end
		{false, line}
	end

	private def self.starts_block?(line : String) : MarkdownBlock?
		if heading = atx_heading?(line)
			return MarkdownBlock.new(heading)
		elsif fence = code_fence?(line)
			return MarkdownFencedCodeBlock.new(fence)
		elsif item = unordered_list_item?(line)
			block = MarkdownBlock.new(item)
			line[item.total_width..]?.try do |l|
				block.content << l
			end
			return block
		end
	end

	# Determines whether *line* is an ATX heading.
	# An ATX heading starts with one or more `#` characters
	# and its level is determined by their number.
	# The content of the heading, if present, must be separated by one
	# space from the marker prefix.
	def self.atx_heading?(line : String) : MarkdownHeading?
		level = line.each_char.take_while{ |c| c == '#' }.size
		if level > 0
			if line[level]? == ' '
				MarkdownHeading.new(level, line[level+1..]? || "")
			else
				MarkdownHeading.new(level)
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

	def self.code_fence?(str : String) : MarkdownFence?
		length, type, indent, infostr = self.repeated_char?(
			str, {'`', '~'}, max_indent: 3)
		if length >= 3
			MarkdownFence.new(length, type, indent, infostr)
		end
	end

	def self.unordered_list_item?(line : String) : MarkdownListItem?
		chars = line.each_char
		indent = 0
		while (c = chars.next) == ' ' && indent < 3
			indent += 1
		end
		if c == '-' || c == '+' || c == '*'
			c = c.as Char
		else
			return nil
		end
		spaces = 0
		while chars.next == ' ' && spaces < 4
			spaces += 1
		end
		MarkdownListItem.new(c, indent, indent + spaces + 1)
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
		if c.is_a? Char && c.in? characters
			while chars.next == c
				count += 1
			end
		else
			c = '\0'
		end

		{count, c, indent, str[indent+count..]? || ""}
	end

	private def self.parse_inline(line : String)
	end

	private def self.parents_to_s(parents : Deque(MarkdownBlock))
		parents.join " > "
	end
end

# A block element in a Markdown document.
private class MarkdownBlock
	property type : BlockType
	property children : Array(MarkdownBlock) = [] of MarkdownBlock
	property content : Array(String) = [] of String

	def initialize(@type)
	end

	# Converts the tree of Markdown elements under `self` into `Markup`.
	def build : Markup
		result = @type.markup
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
		io << type
	end
end

private abstract class BlockType
	abstract def markup : Markup

	def to_s(io : IO)
		io << self.class.name[8..]
	end
end

private class MarkdownParagraph < BlockType
	def markup : Paragraph
		Paragraph.new
	end
end

private class MarkdownHeading < BlockType
	property level : Int32
	property content : String

	def initialize(@level, @content = "")
	end

	def markup : Markup
		Bold.new(content)  # TODO: Change to heading
	end
end

private class MarkdownFence < BlockType
	getter type : Char
	getter length : Int32
	getter indent : Int32
	getter info_string : String

	def initialize(@length, @type, @indent, @info_string)
	end

	def markup : Markup
		Preformatted.new("")
	end

	def ends?(start : MarkdownFence)
		@indent == start.indent &&
		@type == start.type &&
		@length >= start.length
	end
end

private class MarkdownFencedCodeBlock < MarkdownBlock
	def build : Preformatted
		Preformatted.new content.join("\n")
	end
end

private class MarkdownList < BlockType
	property type : Char

	def initialize(@type)
	end

	def initialize(item : MarkdownListItem)
		initialize(item.type)
	end

	def markup : Markup
		if type == '-' || type == '+' || type == '*'
			UnorderedList.new([] of Markup)
		elsif type == '.' || type == ')'
			OrderedList.new([] of Markup)
		else
			raise "Wrong list type: '#{type}'"
		end
	end
end

private class MarkdownListItem < BlockType
	property type : Char
	property indent : Int32
	property total_width : Int32

	def initialize(@type, @indent, @total_width)
	end

	def markup : Markup
		Item.new
	end
end
