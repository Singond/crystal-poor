require "./spec_helper"
require "../src/whitespace_handler"

include Poor

describe WhitespaceHandler do
	str : IO = IO::Memory.new
	io : IO = WhitespaceHandler.new(str)

	before_each do
		str = IO::Memory.new
		io = WhitespaceHandler.new(str)
	end

	it "trims trailing whitespace from line" do
		io << "hello   "
		str.to_s.should eq "hello"
	end

	it "trims trailing whitespace from line" do
		io << "hello"
		io << "    "
		str.to_s.should eq "hello"
	end

	it "preserves trailing whitespace in line" do
		io << "    hello"
		str.to_s.should eq "    hello"
	end

	it "preserves trailing whitespace in line" do
		io << "    "
		io << "hello"
		str.to_s.should eq "    hello"
	end

	it "preserves whitespace between words" do
		io << "hello world  "
		str.to_s.should eq "hello world"
	end

	it "preserves whitespace between words" do
		io << "hello "
		io << "world  "
		str.to_s.should eq "hello world"
	end

	it "trims whitespace before newline" do
		io << "hello   \nworld  "
		str.to_s.should eq "hello\nworld"
	end

	it "trims whitespace before newline" do
		io << "hello   "
		io << '\n'
		io << "world  "
		str.to_s.should eq "hello\nworld"
	end

	it "trims trailing newline" do
		io << "hello world   \n"
		io << "how are you?\n"
		str.to_s.should eq "hello world\nhow are you?"
	end

	describe "#ensure_ends_with" do
		it "adds whitespace if not already present" do
			io << "hello"
			io.ensure_ends_with(" ")
			io << "world"
			str.to_s.should eq "hello world"
		end

		it "does not add anything if already ends with whitespace" do
			io << "hello "
			io.ensure_ends_with(" ")
			io << "world"
			str.to_s.should eq "hello world"
		end

		it "does not add anything if already ends with whitespace" do
			io << "hello\n\n"
			io.ensure_ends_with("\n")
			io << "world"
			str.to_s.should eq "hello\n\nworld"
		end

		it "does not add anything if already ends with whitespace" do
			io << "hello\n\n"
			io.ensure_ends_with("\n\n")
			io << "world"
			str.to_s.should eq "hello\n\nworld"
		end
	end
end
