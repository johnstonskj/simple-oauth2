#lang scribble/manual

@(require racket/sandbox
          scribble/core
          scribble/eval
          (for-label racket/base
                     racket/contract))

@;{============================================================================}
@(define example-eval (make-base-eval
                      '(require racket/string
                                oauth2)))

@;{============================================================================}
@title[]{OpenID Connect 1.0}

OpenID Connect 1.0 is a simple identity
layer on top of the OAuth 2.0 [@hyperlink["https://tools.ietf.org/html/rfc6749"]{RFC6749}]
protocol. It enables Clients to verify the identity of the End-User based on the authentication
performed by an Authorization Server, as well as to obtain basic profile information about
the End-User in an interoperable and REST-like manner.

This implementation references the following specifications/RFCs.

@itemlist[
          @item{@hyperlink["https://openid.net/specs/openid-connect-core-1_0.html"]{OpenID
                  Connect Core 1.0 incorporating errata set 1}.}
          @item{@hyperlink["https://tools.ietf.org/html/rfc7523"]{JSON Web Token (JWT)
                  Profile for OAuth 2.0 Client Authentication and Authorization Grants}.}
          @item{@hyperlink["https://tools.ietf.org/html/rfc7521"]{Assertion Framework
                  for OAuth 2.0 Client Authentication and Authorization Grants}.}
          @item{@hyperlink["https://tools.ietf.org/html/rfc6755"]{An IETF URN
                  Sub-Namespace for OAuth}.}
          ]

@;{============================================================================}
@section[]{Module oauth2/client/openid.}
@defmodule[oauth2/client/openid]

TBD