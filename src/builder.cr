require "./markup"

abstract class Poor::BuilderBase
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
end

class Poor::Builder < Poor::BuilderBase
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

	def get
		@root || raise "The builder is empty"
	end
end

class Poor::Stream < Poor::BuilderBase

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
