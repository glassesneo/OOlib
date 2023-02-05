# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [v0.6.1] -2023-2-5
## Fixed
- a bug that prevent working from exported variables

## [v0.6.0] -2023-2-5
## Removed
- Argument type inference
- Support for generics

## [v0.5.0] -2022-9-24
## Added
- NamedTuple implementation [#78](https://github.com/Glasses-Neo/OOlib/issues/78)
  - classes aliasing tuples are now converted to named tuples and member variables can be defined
- Argument type inference [#101](https://github.com/Glasses-Neo/OOlib/issues/101)
  - types of arguments in constructors are now inserted automatically
- Implemented procedures in `protocol` [#94](https://github.com/Glasses-Neo/OOlib/issues/94)
  - procedures can now be implemented in protocols
- `super` for constructor of inheritance classes [#102](https://github.com/Glasses-Neo/OOlib/issues/102)
- `{.initial.}` to set initial values [#118](https://github.com/Glasses-Neo/OOlib/issues/118)

## Removed
- Old constructors are now removed [#96](https://github.com/Glasses-Neo/OOlib/issues/96)

## [v0.4.3] -2022-5-22
### Fixed
- a bug that `toInterface` was not exported

## [v0.4.2] - 2022-5-22
### Fixed
- a bug that `protocol` was not exported

## [v0.4.1] - 2022-5-21
### Fixed
- exported properties in implementation classes now work properly [#106](https://github.com/Glasses-Neo/OOlib/issues/106)
- `func` in implementation classes now don't cause errors [#107](https://github.com/Glasses-Neo/OOlib/issues/107)

### Changed
- Improved error indication for lack of properties in implementation classes

## [v0.4.0] - 2022-5-5
### Added
- `protocol` that defines a tuple for an interface [#76](https://github.com/Glasses-Neo/OOlib/issues/76)
  - `toInterface` is used for interface implementations
  - Properties marked with `{.ignored.}` is ignored when interfaces are implemented
  - `isProtocol` to check a type is protocol or not
- Omission of body [#85](https://github.com/Glasses-Neo/OOlib/issues/85)
  - `class` and `protocol` are now called without their bodies
- Alternative constructor [#77](https://github.com/Glasses-Neo/OOlib/issues/77)
- Support for generics [#93](https://github.com/Glasses-Neo/OOlib/issues/93)

### Deprecated
- `newType`
  - Use `Type.new` instead

## [v0.3.0] - 2021-10-16
### Added
- Type inference for default args [#55](https://github.com/Glasses-Neo/OOlib/pull/55)
  - Member variables with default values can now be defined without type annotation
- Class data constants [#56](https://github.com/Glasses-Neo/OOlib/issues/56)
- `isClass` to check a type is class or not [#27](https://github.com/Glasses-Neo/OOlib/issues/27)
- Alias class [#25](https://github.com/Glasses-Neo/OOlib/issues/25)
- `{.noNewDef.}` to not define constructors [#43](https://github.com/Glasses-Neo/OOlib/issues/43)

## [v0.2.2] - 2021-8-26 [YANKED]
### Fixed
- A bug that prevented `{.open.}` from working [#42](https://github.com/Glasses-Neo/OOlib/issues/42)

### Changed
- Disabled auto-definition of subclass constructors [#44](https://github.com/Glasses-Neo/OOlib/issues/44)
  - Constructors are now not defined automatically in subclasses
- Subclasses are now warning when `{.open.}` is used together [#42](https://github.com/Glasses-Neo/OOlib/issues/42)

## [v0.2.1] - 2021-8-23 [YANKED]
### Fixed
- A bug in constructors [#42](https://github.com/Glasses-Neo/OOlib/issues/45)

## [v0.2.0] - 2021-8-22
### Added
- Auto-definition of constructors [#6](https://github.com/Glasses-Neo/OOlib/issues/6)
- Assistance with constructor definition [#6](https://github.com/Glasses-Neo/OOlib/issues/)
- `{.open.}` to allow inheritance [#13](https://github.com/Glasses-Neo/OOlib/issues/13)
- Support for `converter` [#16](https://github.com/Glasses-Neo/OOlib/issues/16)
- `super` keyword for `method` [#20](https://github.com/Glasses-Neo/OOlib/issues/20)

### Fixed
- A bug when variables are marked with `*` [#37](https://github.com/Glasses-Neo/OOlib/issues/37)
## v0.1.0 - 2021-8-1
- 🎉 First release!

[v0.5.0]: https://github.com/Glasses-Neo/OOlib/compare/0.4.3..0.5.0
[v0.4.3]: https://github.com/Glasses-Neo/OOlib/compare/0.4.2..0.4.3
[v0.4.2]: https://github.com/Glasses-Neo/OOlib/compare/0.4.1..0.4.2
[v0.4.1]: https://github.com/Glasses-Neo/OOlib/compare/0.4.0..0.4.1
[v0.4.0]: https://github.com/Glasses-Neo/OOlib/compare/0.3.0...0.4.0
[v0.3.0]: https://github.com/Glasses-Neo/OOlib/compare/0.2.2...0.3.0
[v0.2.2]: https://github.com/Glasses-Neo/OOlib/compare/0.2.1...0.2.2
[v0.2.1]: https://github.com/Glasses-Neo/OOlib/compare/0.2.0...0.2.1
[v0.2.0]: https://github.com/Glasses-Neo/OOlib/compare/0.1.0...0.2.0
