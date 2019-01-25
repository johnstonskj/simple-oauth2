# Racket package simple-oauth2

[![GitHub release](https://img.shields.io/github/release/johnstonskj/simple-oauth2.svg?style=flat-square)](https://github.com/johnstonskj/simple-oauth2/releases)
[![Travis Status](https://travis-ci.org/johnstonskj/simple-oauth2.svg)](https://www.travis-ci.org/johnstonskj/simple-oauth2)
[![Coverage Status](https://coveralls.io/repos/github/johnstonskj/simple-oauth2/badge.svg?branch=master)](https://coveralls.io/github/johnstonskj/simple-oauth2?branch=master)
[![raco pkg install simple-oauth2](https://img.shields.io/badge/raco%20pkg%20install-simple--oauth2-blue.svg)](http://pkgs.racket-lang.org/package/simple-oauth2)
[![Documentation](https://img.shields.io/badge/raco%20docs-simple--oauth2-blue.svg)](http://docs.racket-lang.org/simple-oauth2/index.html)
[![GitHub stars](https://img.shields.io/github/stars/johnstonskj/simple-oauth2.svg)](https://github.com/johnstonskj/simple-oauth2/stargazers)
![MIT License](https://img.shields.io/badge/license-MIT-118811.svg)

This package provides an implementation of following set of OAuth2 standards:

1. [https://tools.ietf.org/html/rfc6749](The OAuth 2.0 Authorization Framework)
2. [https://tools.ietf.org/html/rfc7636](Proof Key for Code Exchange (PKCE) by OAuth Public Clients)
3. [https://tools.ietf.org/html/rfc7009](OAuth 2.0 Token Revocation)
4. [https://tools.ietf.org/html/rfc7662](OAuth 2.0 Token Introspection)

The package will also provide some example command-line tools for accessing common services.

Racket already provides two packages with embedded OAuth implementations, 1) *[https://pkgs.racket-lang.org/package/webapi](Implementations of a few web APIs, including OAuth2, PicasaWeb, and Blogger)* and 2) *[https://pkgs.racket-lang.org/package/google](Google APIs (Drive, Plus, ...) for Racket)*. The difference between these and simple-oauth2 is an intent to be an extensible framework that as well as providing clear implementations of the specific requests and the grant flows, also provides a credential store for client and token persistence.


## Modules

* `oauth2` - common data structures.
* `oauth2/client` - client API representing all request types.
* `oauth2/client-flow` - client API the provides higher-level grant flows.
* `oauth2/storage/clients` - a storage API for persisting client details.
* `oauth2/storage/profiles` - a storage API for persisting user profiles, including tokens.

## Example

```scheme
(require oauth2 
		 oauth2/client
		 oauth2/storage/clients)

;; add example here
```

## Tools

TBD

## Installation

* To install (from within the package directory): `raco pkg install`
* To install (once uploaded to [pkgs.racket-lang.org](https://pkgs.racket-lang.org/)): `raco pkg install simple-oauth2`
* To uninstall: `raco pkg remove simple-oauth2`
* To view documentation: `raco docs simple-oauth2`

## History

* **0.1** - Initial Version; the client interface is reasonably stable, but only the authorization API has been tested.

[![Racket Language](https://raw.githubusercontent.com/johnstonskj/racket-scaffold/master/scaffold/plank-files/racket-lang.png)](https://racket-lang.org/)
