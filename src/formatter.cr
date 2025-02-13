require "./markup"

module Poor::Formatter
	@parents = Deque(Markup).new

	def format(text : Markup)
		format_internal(text)
	end

	protected def format_internal(text : Markup)
		text.each_token do |t|
			self << t
		end
	end

	abstract def open_element(element : Markup)
	abstract def close_element(element : Markup)

	def <<(element : Markup | Token)
		case element
		when Markup
			@parents.push element
			open_element(element)
		when Token::End
			element = @parents.pop
			close_element(element)
		else
			# Do nothing
		end
	end
end
