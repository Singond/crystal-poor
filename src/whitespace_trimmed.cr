class Poor::WhitespaceTrimmed < IO
	@io : IO
	@whitespace = Deque(UInt8).new

	def initialize(@io : IO)
	end

	def read(slice : Bytes)
		0
	end

	def write(slice : Bytes) : Nil
		slice.each do |b|
			if b == 0x20
				@whitespace << b
			elsif b == 0x0a
				# Remove leading spaces
				while @whitespace.first? == 0x20
					@whitespace.shift
				end
				@whitespace << b
			else
				@whitespace.size.times do
					@io.write_byte @whitespace.shift
				end
				@io.write_byte b
			end
		end
	end
end
