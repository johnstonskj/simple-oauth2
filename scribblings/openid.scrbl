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
@title[]{OpenID Client}

@hyperlink["https://openid.net/connect/"]{OpenID Connect 1.0} is a simple identity
layer on top of the OAuth 2.0 [@hyperlink["https://tools.ietf.org/html/rfc6749"]{RFC6749}]
protocol. It enables Clients to verify the identity of the End-User based on the authentication
performed by an Authorization Server, as well as to obtain basic profile information about
the End-User in an interoperable and REST-like manner.

