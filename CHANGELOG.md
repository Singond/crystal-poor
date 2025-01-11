Changelog
=========

[Unreleased]
------------
### Added
- Output can now be generated on the fly, without building the whole
  `Markup` object first. Instead, individual elements can be opened
  and closed as needed and output is generated immediately.
  To use this feature, see the `Poor::Stream` class.

### Fixed
- Printing of preformatted text blocks in terminal.
  Previously, the text of the block was duplicated.

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
