require "./spec_helper"
require "../src/markdown"

include Poor
include Poor::Markdown

def parse(str : String) : Markup
	b = Builder.new
	Markdown.parse(IO::Memory.new(str), b)
	b.get
end

describe Markdown do
	doc : Markup = Base.new

	context "with simple paragraphs" do
		before_each do
			doc = parse(<<-MARKDOWN)
			Lorem ipsum dolor sit amet, consectetur adipiscing elit.
			Quisque convallis pretium fringilla.

			Phasellus sed arcu ut ex tincidunt vehicula.
			Praesent vel aliquet felis.

			Magna non posuere tincidunt.
			MARKDOWN
		end

		it "can parse paragraphs" do
			doc.children.size.should eq 3
			doc.children.all?(&.is_a? Paragraph).should be_true
			pars = doc.children
			pars[0].text.should start_with "Lorem ipsum dolor sit amet"
			pars[0].text.should end_with "Quisque convallis pretium fringilla."
			# pars[1].text.should start_with "Phasellus sed arcu ut"
			pars[1].text.should end_with "Praesent vel aliquet felis."
			# pars[2].text.should eq "Magna non posuere tincidunt."
		end
	end

	context "with headings and paragraphs" do
		before_each do
			doc = parse(<<-MARKDOWN)
			# Lorem Ipsum
			Lorem ipsum dolor sit amet, consectetur adipiscing elit.
			Quisque convallis pretium fringilla.
			## Dolor Sit Amet
			Phasellus sed arcu ut ex tincidunt vehicula.
			Praesent vel aliquet felis.
			### Vestibulum Laoreet
			Magna non posuere tincidunt.
			### Ut Congue
			In hac habitasse platea dictumst.
			## Consectetur Adipisci Elit
			Mauris erat arcu, vehicula nec magna vel, tincidunt maximus nisl.
			Magna non posuere tincidunt, tortor sem vehicula tellus.
			MARKDOWN
		end

		it "can parse headings" do
			# TODO: Change Bold to heading, once implemented
			doc.children[0].should be_a Bold
			doc.children[0].text.should eq "Lorem Ipsum"
			doc.children[2].should be_a Bold
			doc.children[2].text.should eq "Dolor Sit Amet"
			doc.children[4].should be_a Bold
			doc.children[4].text.should eq "Vestibulum Laoreet"
			doc.children[6].should be_a Bold
			doc.children[6].text.should eq "Ut Congue"
			doc.children[8].should be_a Bold
			doc.children[8].text.should eq "Consectetur Adipisci Elit"
		end

		it "can parse paragraphs" do
			doc.children[1].should be_a Paragraph
			doc.children[1].text.should start_with "Lorem ipsum dolor sit amet"
			doc.children[1].text.should end_with "pretium fringilla."
			doc.children[3].should be_a Paragraph
			doc.children[3].text.should start_with "Phasellus sed arcu"
			doc.children[5].should be_a Paragraph
			doc.children[5].text.should start_with "Magna non posuere"
			doc.children[7].should be_a Paragraph
			doc.children[7].text.should start_with "In hac habitasse"
			doc.children[9].should be_a Paragraph
			doc.children[9].text.should start_with "Mauris erat arcu, vehicula"
		end
	end

	it "allows empty ATX headings" do
		doc = parse(<<-MARKDOWN)
		##
		MARKDOWN
		doc.children[0].should be_a Bold
	end

	context "with setext-style headings" do
		before_each do
			doc = parse(<<-MARKDOWN)
			Lorem Ipsum
			===========

			Lorem ipsum dolor sit amet, consectetur adipiscing elit.
			Quisque convallis pretium fringilla.

			Dolor Sit Amet
			--------------
			Phasellus sed arcu ut ex tincidunt vehicula.
			Praesent vel aliquet felis.
			### Vestibulum Laoreet
			Magna non posuere tincidunt.
			### Ut Congue
			In hac habitasse platea dictumst.

			Consectetur Adipisci Elit
			-------------------------
			Mauris erat arcu, vehicula nec magna vel, tincidunt maximus nisl.
			Magna non posuere tincidunt, tortor sem vehicula tellus.
			MARKDOWN
		end

		it "can parse headings" do
			# TODO: Change Bold to heading, once implemented
			doc.children[0].should be_a Bold
			doc.children[0].text.should eq "Lorem Ipsum"
			doc.children[2].should be_a Bold
			doc.children[2].text.should eq "Dolor Sit Amet"
			doc.children[4].should be_a Bold
			doc.children[4].text.should eq "Vestibulum Laoreet"
			doc.children[6].should be_a Bold
			doc.children[6].text.should eq "Ut Congue"
			doc.children[8].should be_a Bold
			doc.children[8].text.should eq "Consectetur Adipisci Elit"
		end

		it "can parse paragraphs" do
			doc.children[1].should be_a Paragraph
			doc.children[1].text.should start_with "Lorem ipsum dolor sit amet"
			doc.children[1].text.should end_with "pretium fringilla."
			doc.children[3].should be_a Paragraph
			doc.children[3].text.should start_with "Phasellus sed arcu"
			doc.children[5].should be_a Paragraph
			doc.children[5].text.should start_with "Magna non posuere"
			doc.children[7].should be_a Paragraph
			doc.children[7].text.should start_with "In hac habitasse"
			doc.children[9].should be_a Paragraph
			doc.children[9].text.should start_with "Mauris erat arcu, vehicula"
		end
	end

	it "can parse simple unnumbered list" do
		doc = parse(<<-MARKDOWN)
		- Mauris erat arcu.
		  Ut elementum malesuada ante.
		- Vehicula nec magna vel
		- Tincidunt maximus nisl
		MARKDOWN
		list = doc.children[0]
		list.should be_a UnorderedList
		list.children.size.should eq 3
		list.children[0].should be_a Item
		list.children[0].text.should start_with "Mauris erat arcu."
		list.children[0].text.should end_with "malesuada ante."
		list.children[1].should be_a Item
		list.children[1].text.should eq "Vehicula nec magna vel"
		list.children[2].should be_a Item
		list.children[2].text.should eq "Tincidunt maximus nisl"
	end

	it "separates unnumbered list from surrounding paragraphs" do
		doc = parse(<<-MARKDOWN)
		Lorem ipsum dolor sit amet, consectetur adipiscing elit.
		Quisque convallis pretium fringilla.
		- Mauris erat arcu.
		  Ut elementum malesuada ante.
		- Vehicula nec magna vel
		- Tincidunt maximus nisl
		Phasellus sed arcu ut ex tincidunt vehicula.
		Praesent vel aliquet felis.
		MARKDOWN

		doc.children.size.should eq 3
		doc.children[0].should be_a Paragraph
		doc.children[0].text.should start_with "Lorem ipsum"
		doc.children[0].text.should end_with "pretium fringilla."

		list = doc.children[1]
		list.should be_a UnorderedList
		list.children.size.should eq 3
		list.children[0].should be_a Item
		list.children[0].text.should start_with "Mauris erat arcu."
		list.children[0].text.should end_with "malesuada ante."
		list.children[1].should be_a Item
		list.children[1].text.should eq "Vehicula nec magna vel"
		list.children[2].should be_a Item
		list.children[2].text.should eq "Tincidunt maximus nisl"

		doc.children[2].should be_a Paragraph
		doc.children[2].text.should start_with "Phasellus sed arcu"
		doc.children[2].text.should end_with "aliquet felis."
	end

	it "can parse fenced code block" do
		doc = parse(<<-MARKDOWN)
		```
		def to_html
			String.build do |io|
				to_html io
			end
		end
		```
		MARKDOWN
		doc.children[0].should be_a Preformatted
		doc.children[0].text.should eq <<-EXPECTED
		def to_html
			String.build do |io|
				to_html io
			end
		end
		EXPECTED
	end

	context "with a fenced code block" do
		before_each do
			doc = parse(<<-MARKDOWN)
			Morbi ornare suscipit mi, nec fringilla nisi mollis et.
			Donec suscipit aliquet metus, eget aliquam mauris porta ac.
			```
			def to_html
				String.build do |io|
					to_html io
				end
			end
			```
			Nullam imperdiet magna ac mattis semper.
			MARKDOWN
		end

		it "ends previous paragraph" do
			doc.children[0].should be_a Paragraph
			doc.children[0].text.should end_with "porta ac."
		end

		it "parses the code block" do
			doc.children[1].should be_a Preformatted
			doc.children[1].text.should eq <<-EXPECTED
			def to_html
				String.build do |io|
					to_html io
				end
			end
			EXPECTED
		end

		it "starts paragraph afterward" do
			doc.children[2].should be_a Paragraph
			doc.children[2].text.should start_with "Nullam imperdiet"
		end
	end
end

describe "Markdown.setext_underline?" do
	it "recognizes level 1 heading" do
		Markdown.setext_underline?("============").should eq 1_i8
	end
	it "recognizes level 2 heading" do
		Markdown.setext_underline?("------------").should eq 2_i8
	end
	it "allows 0 to 3 spaces at beginning" do
		Markdown.setext_underline?(" -----------").should eq 2_i8
		Markdown.setext_underline?("  ----------").should eq 2_i8
		Markdown.setext_underline?("   ---------").should eq 2_i8
	end
	it "does not allow more than 3 spaces at beginning" do
		Markdown.setext_underline?("    --------").should be_nil
		Markdown.setext_underline?("     -------").should be_nil
	end
end

def parse_inline(str) : Markup
	p = Markdown::InlineParser.new
	p.parse(str)
	p.get
end

describe InlineParser do
	it "treats blank line as whitespace" do
		par = parse_inline(<<-MARKDOWN.each_line)
		Lorem ipsum dolor sit amet,
		consectetur adipiscing elit.
		MARKDOWN
		par.text.should eq "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
	end

	it "parses line with italics" do
		line = parse_inline("Lorem ipsum _dolor_ sit amet")
		line.children[0].should be_a PlainText
		line.children[0].text.should eq "Lorem ipsum "
		line.children[1].should be_a Italic
		line.children[1].text.should eq "dolor"
		line.children[2].should be_a PlainText
		line.children[2].text.should eq " sit amet"
	end

	describe ".tokenize" do
		it "splits input into raw text and formatting" do
			InlineParser.tokenize("Lorem ipsum _dolor_ sit amet") do |t|
				puts "> #{t}"
			end
		end
	end
end
