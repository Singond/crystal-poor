require "./spec_helper"

include Poor

def simplify(m)
	if m.is_a? Markup
		m.class
	else
		m
	end
end

describe Builder do
	context do
		m = markup()
		before_each do
			b = Builder.new
			par = b.start(Paragraph.new)
			text = b.start(PlainText.new("Lorem ipsum "))
			b.finish(text)
			italic = b.start(Italic.new("dolor"))
			b.finish(italic)
			text = b.start(PlainText.new(" sit amet"))
			b.finish(text)
			b.finish(par)
			m = b.get
		end
		it "constructs Markup using #start and #finish" do
			m.should be_a Paragraph
			m.children.size.should eq 3
			m.children[0].should eq PlainText.new("Lorem ipsum ")
			m.children[1].should eq Italic.new("dolor")
			m.children[2].should eq PlainText.new(" sit amet")
		end
		it "produces same token stream as equivalent Stream" do
			tokens = [] of Markup | Token
			m.each_token { |t| tokens << t }
			tokens.map { |t| simplify(t) } .should eq [
				Paragraph,
					PlainText,
					Token::End,
					Italic,
						PlainText,
						Token::End,
					Token::End,
					PlainText,
					Token::End,
				Token::End
			]
		end
	end
	describe "#start" do
		it "raises if root element has been closed" do
			b = Builder.new
			b.start(Paragraph.new)
			b.finish
			expect_raises(Exception, "closed") do
				b.start(PlainText.new("x"))
			end
		end
	end
	describe "#finish" do
		it "raises if root element has been closed" do
			b = Builder.new
			b.start(Paragraph.new)
			b.finish
			expect_raises(Exception) do
				b.finish
			end
		end
		it "raises if attempting to close non-ancestor element" do
			b = Builder.new
			b.start(Paragraph.new)
			expect_raises(Exception) do
				b.finish(PlainText.new("x"))
			end
		end
	end
	describe "#get" do
		it "raises if no element has been added" do
			expect_raises(Exception, "builder is empty") do
				Builder.new.get
			end
		end
	end
end

describe Stream do
	it "outputs token stream using #start and #finish" do
		tokens = Array(Markup|Token).new
		b = Stream.new(tokens)
		par = b.start(Paragraph.new)
		text = b.start(PlainText.new("Lorem ipsum "))
		b.finish(text)
		italic = b.start(Italic.new("dolor"))
		b.finish(italic)
		text = b.start(PlainText.new(" sit amet"))
		b.finish(text)
		b.finish(par)
		tokens.map { |t| simplify(t) } .should eq [
			Paragraph,
				PlainText,
				Token::End,
				Italic,
					PlainText,
					Token::End,
				Token::End,
				PlainText,
				Token::End,
			Token::End
		]
	end
	describe "#start" do
		pending "raises if root element has been closed" do
			b = Stream.new
			b.start(Paragraph.new)
			b.finish
			expect_raises(Exception, "closed") do
				b.start(PlainText.new("x"))
			end
		end
	end
	describe "#finish" do
		pending "raises if root element has been closed" do
			b = Stream.new
			b.start(Paragraph.new)
			b.finish
			expect_raises(Exception) do
				b.finish
			end
		end
		it "raises if attempting to close non-ancestor element" do
			b = Stream.new([] of Markup | Token)
			b.start(Paragraph.new)
			expect_raises(Exception) do
				b.finish(PlainText.new("x"))
			end
		end
	end
end
