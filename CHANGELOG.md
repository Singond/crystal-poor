Changelog
=========

[0.5.0] - 2025-03-18
--------------------
### Added
- Added new `map_recursive!` method to transform a markup tree by applying
  a function to each element.
- Methods `open` and `close` on builder objects, as alternatives to the
  existing `start` and `finish` methods.
### Changed
- The `Enumerable({Markup,Bool})` and `Iterable({Markup, Bool})` modules
  have been removed from `Markup`. Their functionality is still available
  using the `each_start_end` methods.
  Instead, `Markup` now includes `Indexable::Mutable(Markup)`.

[0.4.0] - 2025-02-22
--------------------
### Added
- Output can now be generated on the fly, without building the whole
  `Markup` object first. Instead, individual elements can be opened
  and closed as needed and output is generated immediately.
  To use this feature, see the `Poor::Stream` class.
- Basic Markdown parser, which can read a Markdown file and convert
  it to `Markup` object. See the `Poor::Markdown` module.

### Fixed
- Printing of preformatted text blocks in terminal.
  Previously, the text of the block was duplicated.
- Separation of paragraphs from surrounding text,
  which sometimes lacked the blank line.

[0.3.0] - 2024-09-05
--------------------
### Added
- This changelog.
- Containers for inline code and preformatted text (like code blocks).
  See `Code` and `Preformatted`.

### Fixed
- Compile-time error when the module was used without `include`.

[0.2.1] - 2024-06-30
--------------------
### Fixed
- Added missing `colorize` import.
