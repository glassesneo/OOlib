# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [v0.2.2] - 2021-8-26 [YANKED]
### Fixed
- a bug that prevented `{.open.}` from working [#42](https://github.com/Glasses-Neo/OOlib/issues/42)

### Changed
- disabled auto definition of subclass constructor [#44](https://github.com/Glasses-Neo/OOlib/issues/44)
  - constructors are now not defined automatically in subclasses
- subclasses are now warning when `{.open.}` is used together [#42](https://github.com/Glasses-Neo/OOlib/issues/42)

## [v0.2.1] - 2021-8-23 [YANKED]
### Fixed
- a bug in constructor [#42](https://github.com/Glasses-Neo/OOlib/issues/45)

## [v0.2.0] - 2021-8-22
### Added
- auto definition of constructor [#6](https://github.com/Glasses-Neo/OOlib/issues/6)
- assistance with constructor definition [#6](https://github.com/Glasses-Neo/OOlib/issues/)
- `{.open.}` to allow inheritance [#13](https://github.com/Glasses-Neo/OOlib/issues/13)
- support for `converter` [#16](https://github.com/Glasses-Neo/OOlib/issues/16)
- `super` keyword for `method` [#20](https://github.com/Glasses-Neo/OOlib/issues/20)

### Fixed
- a bug when variables are marked with `*` [#37](https://github.com/Glasses-Neo/OOlib/issues/37)
## v0.1.0 - 2021-8-1
- 🎉 first release!

[Unreleased]: https://github.com/Glasses-Neo/OOlib/compare/b2478d904a1644509f0f86b921e6f0f8caf747cf...HEAD
[v0.2.2]: https://github.com/Glasses-Neo/OOlib/compare/b33007b4598a58e587eb71d9e991e1af56affa24...b2478d904a1644509f0f86b921e6f0f8caf747cf
[v0.2.1]: https://github.com/Glasses-Neo/OOlib/compare/743a473841f7efdb41652678fe8a224cdbb7b5b4...b33007b4598a58e587eb71d9e991e1af56affa24
[v0.2.0]: https://github.com/Glasses-Neo/OOlib/compare/5a1a0d2aadcbd30d723951d1b8418a653c86bf65...743a473841f7efdb41652678fe8a224cdbb7b5b4
