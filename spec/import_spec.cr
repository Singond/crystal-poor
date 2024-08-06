require "spec"
require "../src/poor"

# NOTE: This spec must be run in isolation from other tests, which use
# the `include Poor` statement. The Make target `check` does this.

style = Poor::TerminalStyle.new
style.line_width = 80
style.justify = true

describe Poor do
	it "can be called without `include Poor`" do
		style = Poor::TerminalStyle.new
		style.line_width = 80
		style.justify = true
		text = Poor.paragraph(
			"Donec vel felis placerat, fermentum quam non, efficitur purus. ",
			Poor.bold("Nulla"), " at orci ", Poor.bold("fermentum"),
			" dignissim dolor id, ", Poor.italic("commodo erat"),
			". Donec laoreet lectus et quam tincidunt laoreet. ",
			Poor.small("Praesent vestibulum metus quis mollis blandit."),
			" Vivamus sit amet ", Poor.bold("tellus"), " at ",
			Poor.italic("nibh auctor"), " consequat. ",
			Poor.bold("Curabitur eu ", Poor.italic("interdum"), " nulla."),
			" Cras posuere in leo et venenatis.",
			<<-TEXT)
			Mauris eget felis eleifend, egestas enim nec, feugiat neque. \
			Donec aliquet volutpat pulvinar. \
			Duis posuere dictum leo, ac luctus orci laoreet ut. \
			Donec eleifend tempus lorem nec accumsan. \
			Duis vitae aliquet ipsum, a cursus urna. \
			Fusce pretium venenatis pulvinar. \
			Aenean convallis lorem ut ligula commodo ultrices.
			TEXT
		formatted = String.build {|io| Poor.format text, io, style}
	end
end
