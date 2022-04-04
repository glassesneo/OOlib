# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
- `protocol` that defines a tuple for an interface [#76](https://github.com/Glasses-Neo/OOlib/issues/76)
  - `toInterface` is used for implementation of interfaces
  - properties marked with `{.ignored.}` is ignored when interfaces are implemented
  - `isProtocol` to check a type is protocol or not
- omission of body [#85](https://github.com/Glasses-Neo/OOlib/issues/85)
  - `class` and `protocol` are now called without their bodies

## [v0.3.0] - 2021-10-16
### Added
- type inference for default args [#55](https://github.com/Glasses-Neo/OOlib/pull/55)
  - member variables with default values can now be defined without type annotation
- class data constants [#56](https://github.com/Glasses-Neo/OOlib/issues/56)
- `isClass` to check a type is class or not [#27](https://github.com/Glasses-Neo/OOlib/issues/27)
- alias class [#25](https://github.com/Glasses-Neo/OOlib/issues/25)
- `{.noNewDef.}` to not define constructors [#43](https://github.com/Glasses-Neo/OOlib/issues/43)

## [v0.2.2] - 2021-8-26 [YANKED]
### Fixed
- a bug that prevented `{.open.}` from working [#42](https://github.com/Glasses-Neo/OOlib/issues/42)

### Changed
- disabled auto-definition of subclass constructors [#44](https://github.com/Glasses-Neo/OOlib/issues/44)
  - constructors are now not defined automatically in subclasses
- subclasses are now warning when `{.open.}` is used together [#42](https://github.com/Glasses-Neo/OOlib/issues/42)

## [v0.2.1] - 2021-8-23 [YANKED]
### Fixed
- a bug in constructors [#42](https://github.com/Glasses-Neo/OOlib/issues/45)

## [v0.2.0] - 2021-8-22
### Added
- auto-definition of constructors [#6](https://github.com/Glasses-Neo/OOlib/issues/6)
- assistance with constructor definition [#6](https://github.com/Glasses-Neo/OOlib/issues/)
- `{.open.}` to allow inheritance [#13](https://github.com/Glasses-Neo/OOlib/issues/13)
- support for `converter` [#16](https://github.com/Glasses-Neo/OOlib/issues/16)
- `super` keyword for `method` [#20](https://github.com/Glasses-Neo/OOlib/issues/20)

### Fixed
- a bug when variables are marked with `*` [#37](https://github.com/Glasses-Neo/OOlib/issues/37)
## v0.1.0 - 2021-8-1
- 🎉 first release!

[Unreleased]: https://github.com/Glasses-Neo/OOlib/compare/5a1e429ea80d9dedc482d918f991140116699dc1...HEAD
[v0.3.0]: https://github.com/Glasses-Neo/OOlib/compare/b2478d904a1644509f0f86b921e6f0f8caf747cf...5a1e429ea80d9dedc482d918f991140116699dc1
[v0.2.2]: https://github.com/Glasses-Neo/OOlib/compare/b33007b4598a58e587eb71d9e991e1af56affa24...b2478d904a1644509f0f86b921e6f0f8caf747cf
[v0.2.1]: https://github.com/Glasses-Neo/OOlib/compare/743a473841f7efdb41652678fe8a224cdbb7b5b4...b33007b4598a58e587eb71d9e991e1af56affa24
[v0.2.0]: https://github.com/Glasses-Neo/OOlib/compare/5a1a0d2aadcbd30d723951d1b8418a653c86bf65...743a473841f7efdb41652678fe8a224cdbb7b5b4
