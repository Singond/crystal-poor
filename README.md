# Poor: A poor man's rich text for Crystal

Poor is a library for producing basic formatted text from Crystal programs.

```
  Poor is a Crystal library for producing formatted text programmatically.  It
  enables you to mark up text with formatting commands and render it into  one
  of the supported formats.

  This is a sample text produced with Poor. Features of the library include:
   1. Wrapping text to specified width with optional margins. Line breaks only
      occur  at  word  boundaries,  hyphenation  is  not implemented yet. This
      example was set to wrap at 80 characters with a left and right margin of
      2 characters.
   2. Marking up paragraphs, ordered and  unordered lists. This is an  ordered
      list in one  paragraph with the  preceding few sentences  (starting with
      “This is a sample”).
   3. Text  justification  by  widening  existing  whitespace. This example is
      justified.
```

The above exapmle was produced with the following source code:
```
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
			Poor.item(<<-ITEM)
				Text justification by widening existing whitespace. \
				This example is justified.
				ITEM
		)
	)
)
style = Poor::TerminalStyle.new
style.line_width = 80
style.left_margin = 2
style.right_margin = 2
style.justify = true
Poor.format(lipsum, style: style)
```

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  poor:
    github: singond/crystal-poor
```

2. Run `shards install`

## Usage

```crystal
require "poor"

# Define text
text = Poor.markup("Hello ", "world");

# Print it into terminal
Poor.format(text)
```

## Contributing

1. Fork it (<https://github.com/singond/dict-protocol/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jan Singon Slany](https://github.com/singond) - creator and maintainer
