require "./markup"

# A base for objects which enable processing markup trees by opening
# and closing individual elements.
abstract class Poor::TreeMaker
	@parents = Deque(Markup).new

	abstract def open(element : Markup)
	abstract def close(element : Markup)

	def add(element : Markup)
		open(element)
		close(element)
	end

	def start(element : Markup)
		open(element)
		@parents.push(element)
		element
	end

	def finish(element : Markup = @parents.last)
		finish_children(element)
		if @parents.empty?
			raise ArgumentError.new("Element not found")
		else
			close(@parents.pop)
		end
	end

	def finish_children(element : Markup)
		until @parents.empty? || @parents.last == element
			close(@parents.pop)
		end
	end

	def parent
		@parents.last?
	end
end

# Markup builder which assembles the elements into a tree and exposes
# the root element.
class Poor::Builder < Poor::TreeMaker
	@root : Markup?

	def open(element : Markup)
		if @root.nil?
			@root = element
		elsif (parent = @parents.last?)
			parent.children << element
		else
			raise "Builder has already been closed"
		end
	end

	def close(element : Markup)
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

	def open(element : Markup)
		@formatter << element
		unless element.children.empty?
			element.children.each do |child|
				child.each_token do |token|
					@formatter << token
				end
			end
		end
	end

	def close(element : Markup)
		@formatter << Poor::Token::End
	end
end
