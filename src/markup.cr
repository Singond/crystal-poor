module Poor
	# Abstract representation of a marked-up text.
	abstract struct Markup
		include Indexable::Mutable(Markup)

		def children
			[] of Markup
		end

		def text(io : IO)
			""
		end

		def text
			String.build do |io|
				text io
			end
		end

		def to_html(io : IO)
			text io
		end

		def to_html
			String.build do |io|
				to_html io
			end
		end

		def inspect(io : IO)
			io << '\\'
			io << self.class.name.split("::").last.downcase
			if !children.empty?
				io << "{"
				children.each do |c|
					c.to_s(io)
				end
				io << "}"
			end
		end

		private def pretty_print(pp : PrettyPrint)
			selfname = self.class.name.split("::").last
			pp.text "#{selfname}{"
			pp.group(indent: 2) do
				pp.breakable
				yield
			end
			pp.breakable
			pp.text "}"
		end

		private def pretty_print_children(pp : PrettyPrint)
			children.each_with_index do |c, idx|
				pp.comma if idx > 0
				c.pretty_print(pp)
			end
		end

		def pretty_print(pp : PrettyPrint)
			pretty_print(pp) do
				pretty_print_children(pp)
			end
		end

		def each
			children.each do |c|
				yield c
			end
		end

		def each
			children.each
		end

		def each_recursive
			each_start do |elem|
				yield elem
			end
		end

		def each_recursive
			each_start
		end

		def each_start_end
			iter = HistIterator.new(([self] of Markup).each)
			iters = Deque(HistIterator(Markup)).new
			iters.push iter
			until iters.empty?
				elem = iter.next
				if !elem.is_a?(Iterator::Stop)
					yield({elem, true})
					if elem.children().empty?
						yield({elem, false})
					else
						# Recurse into children
						iter = HistIterator.new(elem.children.each)
						iters.push iter
					end
				else
					# No more leaves in this branch
					if !iters.empty?
						iters.pop
						if !iters.empty?
							# Move to sibling branch
							iter = iters.last
							if last = iter.current
								yield({last, false})
							end
						end
					end
				end
			end
		end

		def each_start
			each_start_end do |elem, start|
				next unless start
				yield elem
			end
		end

		def each_end
			each_start_end do |elem, start|
				next if start
				yield elem
			end
		end

		def each_token
			each_start_end do |elem, start|
				if start
					yield elem
				else
					yield Token::End
				end
			end
		end

		def each_start_end
			MarkupIterator.new(self)
		end

		def each_start
			each_start_end.select {|(_, start)| start}
				.map {|(elem,_)| elem}
		end

		def each_end
			each_start_end.select {|(_, start)| !start}
				.map {|(elem,_)| elem}
		end

		def size
			children.size
		end

		def unsafe_fetch(index : Int)
			children.unsafe_fetch(index)
		end

		def unsafe_put(index : Int, value : Markup)
			children.unsafe_put(index, value)
		end

		def map_recursive!(&func : Markup -> Markup)
			mapped = yield self
			children.map! do |c|
				c.map_recursive! do |elem|
					func.call(elem)
				end
			end
			mapped
		end

		# Converts the rich text into text with ANSI escape codes
		# for display in terminal.
		def to_ansi(io : IO)
			at_start = true
			pending_whitespace = ""

			bold = 0
			italic = 0
			dim = 0
			each_start_end do |e, start|
				if start
					whitespace_written = false
					case e
					when PlainText
						next if e.text.empty?
						at_start = false
						c = Colorize.with
						if bold > 0
							c = c.bold
						end
						if dim > 0
							c = c.dim
						end
						io << pending_whitespace
						whitespace_written = true
						c.surround(io) do
							io << "\e[3m" if italic > 0
							io << e.text
							io << "\e[0m" if italic > 0
						end
					when Bold
						bold += 1
					when Italic
						italic += 1
					when Small
						dim += 1
					when Paragraph
						next if e.text.empty?
						if pending_whitespace.ends_with? "\n\n"
							io << pending_whitespace
							whitespace_written = true
						elsif pending_whitespace.ends_with? "\n"
							io << pending_whitespace
							whitespace_written = true
							io << "\n"
						elsif !at_start
							io << "\n\n"
						end
					end
					pending_whitespace = "" if whitespace_written
				else
					case e
					when Bold
						bold -= 1
					when Italic
						italic -= 1
					when Small
						dim -= 1
					when Paragraph
						pending_whitespace = "\n\n" unless e.text.empty?
					end
				end
			end
		end

		def to_ansi
			String.build do |io|
				to_ansi io
			end
		end
	end

	# A wrapper around an iterator which keeps track of the last
	# element returned by `#next`.
	private class HistIterator(T)
		@current : T? = nil
		def initialize(@iter : Iterator(T))
		end

		def next
			current = @iter.next
			@current = current if current.is_a?(T)
			current
		end

		def current
			@current
		end
	end

	abstract struct Container < Markup
		@value : Array(Markup)
		@@html_tag : String = ""

		def initialize(@value : Array(Markup) = [] of Markup)
		end

		def initialize(*content : Markup | String)
			if content.size == 1
				@value = [to_markup(content[0])] of Markup
			else
				@value = [] of Markup
				content.each do |elem|
					@value << to_markup(elem)
				end
			end
		end

		def children
			@value
		end

		def text(io : IO)
			@value.reduce "" do |alltext, elem|
				io << elem.text
			end
		end

		def to_html(io : IO)
			tag = @@html_tag
			io << "<" << tag << ">" unless tag.empty?
			@value.reduce "" do |alltext, elem|
				io << elem.to_html
			end
			io << "</" << tag << ">" unless tag.empty?
		end
	end

	abstract struct TextContainer < Markup
		@value : PlainText
		@@html_tag : String = ""

		def initialize(text : String)
			@value = PlainText.new(text)
		end

		def children
			[@value] of Markup
		end

		def text(io : IO)
			io << @value
		end

		def to_html(io : IO)
			tag = @@html_tag
			io << "<" << tag << ">" unless tag.empty?
			io << @value
			io << "</" << tag << ">" unless tag.empty?
		end
	end

	struct PlainText < Markup
		def initialize(@text : String)
		end

		def text(io : IO)
			io << @text
		end

		def inspect(io : IO)
			io << @text
		end

		def pretty_print(pp : PrettyPrint)
			pretty_print(pp) do
				@text.pretty_print(pp)
			end
		end
	end

	struct Base < Container
	end

	def markup()
		Base.new()
	end

	def markup(*content : Markup | String)
		if content.size == 1
			to_markup(content[0])
		else
			Base.new(*content)
		end
	end

	class MarkupIterator
		include Iterator({Markup, Bool})

		@iters : Deque(HistIterator(Markup))
		@iter : HistIterator(Markup)
		@last : Markup?

		def initialize(markup : Markup)
			@iter = HistIterator.new(([markup] of Markup).each)
			@iters = Deque(HistIterator(Markup)).new
			@iters.push @iter
		end

		def next
			# Close leaf element
			if last = @last
				@last = nil
				return {last, false}
			end
			# Else get next element from the current iterator
			elem = @iter.next
			if !elem.is_a?(Iterator::Stop)
				if elem.children().empty?
					@last = elem
				else
					# Recurse into children
					@iter = HistIterator.new(elem.children.each)
					@iters.push @iter
				end
				return {elem, true}
			else
				# No more leaves in this branch
				if !@iters.empty?
					@iters.pop
					if !@iters.empty?
						# Move to sibling branch
						@iter = @iters.last
						if last = @iter.current
							return {last, false}
						end
					end
				end
			end
			stop
		end
	end

	struct Italic < Container
		@@html_tag = "i"
	end

	def italic(*content : Markup | String)
		Italic.new(*content)
	end

	struct Bold < Container
		@@html_tag = "b"
	end

	def bold(*content : Markup | String)
		Bold.new(*content)
	end

	struct Small < Container
		@@html_tag = "small"
	end

	def small(*content : Markup | String)
		Small.new(*content)
	end

	struct Code < TextContainer
		@@html_tag = "code"
	end

	def code(content : String)
		Code.new(content)
	end

	struct Paragraph < Container
		@@html_tag = "p"
		# def text(io : IO)
		# 	io << "\n\n"
		# 	super
		# end
	end

	def paragraph(*content : Markup | String)
		Paragraph.new(*content)
	end

	struct Heading < Container
		getter level : Int32

		def initialize(content, @level)
			super(content)
		end

		def pretty_print(pp : PrettyPrint)
			pretty_print(pp) do
				pp.text "level=#{level} "
				pp.comma
				pretty_print_children(pp)
			end
		end
	end

	def heading(*content, level : Int32)
		Heading.new(*content, level)
	end

	def heading(level : Int, *content)
		Heading.new(*content, level: level)
	end

	struct Preformatted < Markup
		def initialize(@text : String)
		end

		def text(io : IO)
			io << @text
		end

		def inspect(io : IO)
			io << '\\'
			io << self.class.name.split("::").last.downcase
			io << "{"
			@text.inspect(io)
			io << "}"
		end

		def pretty_print(pp : PrettyPrint)
			pretty_print(pp) do
				@text.pretty_print(pp)
			end
		end
	end

	def preformatted(*content : String)
		Preformatted.new(*content)
	end

	struct OrderedList < Container
		@@html_tag = "ol"

		def initialize(items : Array(Markup))
			@value = items
		end
	end

	def ordered_list(*items : Item)
		OrderedList.new(items.to_a.map{|i| i.as Markup})
	end

	struct UnorderedList < Container
		@@html_tag = "ul"

		def initialize(items : Array(Markup))
			@value = items
		end
	end

	def unordered_list(*items : Item)
		UnorderedList.new(items.to_a.map{|i| i.as Markup})
	end

	struct Item < Container
		@@html_tag = "li"
	end

	def item(*content : Markup | String)
		Item.new(*content)
	end

	struct LabeledParagraph < Container
		@@html_tag = "p"
		property label : String
		property indent : Int32

		def initialize(@label, *content : Markup | String,
				@indent = 4)
			if content.size == 1
				@value = [to_markup(content[0])] of Markup
			else
				@value = [] of Markup
				content.each do |elem|
					@value << to_markup(elem)
				end
			end
		end
	end

	def labeled_paragraph(label : String, *content : Markup | String, **args)
		LabeledParagraph.new(label, *content, **args)
	end
end

enum Poor::Token
	End
end

private def to_markup(value : Poor::Markup | String) : Poor::Markup
	case value
	in Poor::Markup
		value
	in String
		Poor::PlainText.new(value)
	end
end
