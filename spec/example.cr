require "../src/markup"
require "../src/term"

include Poor

style = Poor::TerminalStyle.new
style.line_width = 80
style.left_margin = 2
style.right_margin = 2
style.justify = true

lipsum = Poor.markup(
	Poor.paragraph(<<-PAR),
		Poor is a Crystal library for producing formatted text \
		programmatically. \
		It enables you to mark up text with formatting commands \
		and render it into one of the supported formats.
		PAR
	Poor.paragraph(
		"This is a sample text produced with Poor. ",
		"Features of the library include:",
		Poor.ordered_list(
			Poor.item(<<-ITEM),
				Wrapping text to specified width with optional margins. \
				Line breaks only occur at word boundaries, \
				hyphenation is not implemented yet. \
				This example was set to wrap at 80 characters \
				with a left and right margin of 2 characters.
				ITEM
			Poor.item(<<-ITEM),
				Marking up paragraphs, ordered and unordered lists. \
				This is an ordered list in one paragraph with the preceding \
				few sentences (starting with “This is a sample”).
				ITEM
			Poor.item(<<-ITEM),
				Text justification by widening existing whitespace. \
				This example is justified.
				ITEM
			Poor.item(<<-ITEM, Poor.preformatted(<<-PRE), <<-MORE)
				Printing pre-formatted text (such as code examples) as-is, \
				with the line breaks unchanged. \
				The following code block is embedded inside this list item:
				ITEM
				def to_html(io : IO)
				    tag = @@html_tag
				    io << "<" << tag << ">" unless tag.empty?
				    @value.reduce "" do |alltext, elem|
				        io << elem.to_html
				    end
				    io << "</" << tag << ">" unless tag.empty?
				end
				PRE
				The block is indented with respect to the parent block \
				(list item in this case). \
				This example uses the default indent, but the amount \
				is configurable.
				MORE
		)
	)
)

Poor.format(lipsum, style: style)
