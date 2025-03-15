require "./markup"

# A base for objects which enable processing markup trees by opening
# and closing individual elements.
abstract class Poor::TreeMaker
	@parents = Deque(Markup).new

	abstract def open_element(element : Markup)
	abstract def close_element(element : Markup)

	def add(element : Markup)
		open_element(element)
		close_element(element)
	end

	def open(element : Markup)
		open_element(element)
		@parents.push(element)
		element
	end

	# Alias for `#open`.
	def start(element : Markup)
		open(element)
	end

	def close(element : Markup = @parents.last)
		close_children(element)
		if @parents.empty?
			raise ArgumentError.new("Element not found")
		else
			close_element(@parents.pop)
		end
	end

	# Alias for `#close`.
	def finish(element : Markup = @parents.last)
		close(element)
	end

	def close_children(element : Markup)
		until @parents.empty? || @parents.last == element
			close_element(@parents.pop)
		end
	end

	# Alias for `#close_children`.
	def finish_children(element : Markup)
		close_children(element)
	end

	def parent
		@parents.last?
	end
end

# Markup builder which assembles the elements into a tree and exposes
# the root element.
class Poor::Builder < Poor::TreeMaker
	@root : Markup?

	def open_element(element : Markup)
		if @root.nil?
			@root = element
		elsif (parent = @parents.last?)
			parent.children << element
		else
			raise "Builder has already been closed"
		end
	end

	def close_element(element : Markup)
	end

	# Returns the root element of the built markup tree.
	def get
		@root || raise "The builder is empty"
	end
end

# Markup processor which enables processing markup elements on the fly
# by sending the token stream directly to the given formatter.
# This avoids creating the intermediate markup tree.
class Poor::Stream < Poor::TreeMaker

	def initialize(@formatter : Poor::Formatter | Array(Markup|Token))
	end

	def open_element(element : Markup)
		@formatter << element
		unless element.children.empty?
			element.children.each do |child|
				child.each_token do |token|
					@formatter << token
				end
			end
		end
	end

	def close_element(element : Markup)
		@formatter << Poor::Token::End
	end
end
