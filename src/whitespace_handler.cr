class Poor::WhitespaceHandler < IO
	@io : IO
	@whitespace = Deque(UInt8).new
	@no_separation = false

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
				lstrip
				@whitespace << b
			else
				lstrip 0x0a if @no_separation
				@whitespace.size.times do
					@io.write_byte @whitespace.shift
				end
				@io.write_byte b
				@no_separation = false
			end
		end
	end

	# Removes leading spaces from the whitespace buffer
	private def lstrip(char = 0x20)
		while @whitespace.first? == char
			@whitespace.shift
		end
	end

	# Ensures that the current pending whitespace ends with
	# the given whitespace string *whitespace*.
	# Raises if the argument contains non-whitespace characters.
	def ensure_ends_with(whitespace : String)
		if !whitespace.blank?
			raise "Argument must be whitespace-only"
		end
		overlap = Math.min(@whitespace.size, whitespace.bytesize)
		bytes = whitespace.bytes
		while overlap > 0
			i = 0
			until i >= overlap ||
					@whitespace[-overlap + i] != whitespace[i]
				i += 1
			end
			break if i == overlap
			overlap -= 1
		end
		bytes[@whitespace.size - overlap..]?.try &.each do |b|
			@whitespace << b
		end
	end

	def suppress_separation
		@no_separation = true
	end
end
