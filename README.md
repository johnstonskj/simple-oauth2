# Racket package simple-oauth2

[![GitHub release](https://img.shields.io/github/release/johnstonskj/simple-oauth2.svg?style=flat-square)](https://github.com/johnstonskj/simple-oauth2/releases)
[![Travis Status](https://travis-ci.org/johnstonskj/simple-oauth2.svg)](https://www.travis-ci.org/johnstonskj/simple-oauth2)
[![Coverage Status](https://coveralls.io/repos/github/johnstonskj/simple-oauth2/badge.svg?branch=master)](https://coveralls.io/github/johnstonskj/simple-oauth2?branch=master)
[![raco pkg install simple-oauth2](https://img.shields.io/badge/raco%20pkg%20install-simple--oauth2-blue.svg)](http://pkgs.racket-lang.org/package/simple-oauth2)
[![Documentation](https://img.shields.io/badge/raco%20docs-simple--oauth2-blue.svg)](http://docs.racket-lang.org/simple-oauth2/index.html)
[![GitHub stars](https://img.shields.io/github/stars/johnstonskj/simple-oauth2.svg)](https://github.com/johnstonskj/simple-oauth2/stargazers)
![MIT License](https://img.shields.io/badge/license-MIT-118811.svg)

This package provides an implementation of a full client for OAuth 2.0 protected resources with a framework for both authorization and resource servers to follow. It implements, or references, the following set of OAuth 2.0 standards:

1. [The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749) (which implies [The OAuth 2.0 Authorization Framework: Bearer Token Usage](https://tools.ietf.org/html/rfc6750))
2. [Proof Key for Code Exchange (PKCE) by OAuth Public Clients](https://tools.ietf.org/html/rfc7636)
3. [OAuth 2.0 Token Revocation](https://tools.ietf.org/html/rfc7009)
4. [OAuth 2.0 Token Introspection](https://tools.ietf.org/html/rfc7662)

In the same way as RFC6749, this implementation *"defines the use of bearer tokens over HTTP/1.1
   [RFC2616](https://tools.ietf.org/html/2616) using Transport Layer Security (TLS) [RFC5246](https://tools.ietf.org/html/5246) to access
   protected resources."* The package does however also provide example command-line tools for accessing common services.

Racket already provides two packages with embedded OAuth implementations, 1) *[webapi](https://pkgs.racket-lang.org/package/webapi)- Implementations of a few web APIs, including OAuth2, PicasaWeb, and Blogger* and 2) *[google](https://pkgs.racket-lang.org/package/google) - Google APIs (Drive, Plus, ...*. The difference between these and simple-oauth2 is an intent to be an extensible framework that as well as providing clear implementations of the specific requests and the grant flows, also provides a credential store for client and token persistence.


## Modules

* `oauth2` - common data structures.
* `oauth2/client` - client API representing all request types.
* `oauth2/client/flow` - client API that provides higher-level grant flows.
* `oauth2/client/pkce` - client option to support PKCE challenges (RFC7636).
* `oauth2/storage/config` - a storage API for persisting configuration.
* `oauth2/storage/clients` - a storage API for persisting client details.
* `oauth2/storage/tokens` - a storage API for persisting authorization tokens.

## Example

```scheme
(require oauth2
         oauth2/client
         oauth2/storage/clients)

(define response-channel
  (request-authorization-code
    (get-client "Fitbit API")
    (list "sleep" "weight")))

(displayln (format "returned auth code: ~a" (channel-get response-channel)))

(authorization-complete)
```

## Tools

* `fitbit` - allows retrieval of sleep and weight records.
* `livongo` - allows retrieval of blood glucose meter readings.

## Installation

* To install (from within the package directory): `raco pkg install`
* To install (once uploaded to [pkgs.racket-lang.org](https://pkgs.racket-lang.org/)): `raco pkg install simple-oauth2`
* To uninstall: `raco pkg remove simple-oauth2`
* To view documentation: `raco docs simple-oauth2`

## Work in Progress

* Support for [JSON Web Tokens](https://tools.ietf.org/html/rfc7519).
* Support for [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html).
* Authorization Server framework.
* Resource Server framework.
* Potential tools:
  * [Ōura Ring](https://cloud.ouraring.com/docs/).


## History

* **1.2** - Client Additions; factored out PKCE module, simplified client module, added `grant-token/extension` API procedure.
* **1.1** - Client Tools; implemented second client tool (for Livongo blood glucose monitor). Better client response formatting.
* **1.0** - Stable Client; the client interface for code grant and token refresh is now complete. Fitbot tool working for sleep and weight scopes.
* **0.1** - Initial Version; the client interface is reasonably stable, but only the authorization API has been tested.

[![Racket Language](https://raw.githubusercontent.com/johnstonskj/racket-scaffold/master/scaffold/plank-files/racket-lang.png)](https://racket-lang.org/)
