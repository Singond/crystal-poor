require "./spec_helper"
require "../src/whitespace_trimmed"

include Poor

describe WhitespaceTrimmed do
	io : IO = IO::Memory.new
	str : IO = IO::Memory.new

	before_each do
		str = IO::Memory.new
		io = WhitespaceTrimmed.new(str)
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
end
