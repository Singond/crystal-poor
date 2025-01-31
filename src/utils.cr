class String
	def starts_with_spaces?(number)
		chars = each_char
		number.times do
			return false unless chars.next == ' '
		end
		true
	end
end
