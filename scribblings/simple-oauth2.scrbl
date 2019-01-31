#lang scribble/manual

@(require racket/file
          scribble/core)

@;{============================================================================}

@title[#:version "1.0"]{Package simple-oauth2.}
@author[(author+email "Simon Johnston" "johnstonskj@gmail.com")]

This package provides an implementation of a full client (both flow-based and
  request-based) for OAuth 2.0 protected resources with a framework for both
  authorization and resource servers to follow. It implements, or references,
  the following set of OAuth 2.0 standards:

@itemlist[
  @item{@hyperlink["https://tools.ietf.org/html/rfc6749"]{The OAuth 2.0 Authorization Framework},
  which implies @hyperlink["https://tools.ietf.org/html/rfc6750"]{The OAuth 2.0 Authorization Framework: Bearer Token Usage}}
  @item{@hyperlink["https://tools.ietf.org/html/rfc7636"]{Proof Key for Code Exchange (PKCE) by OAuth Public Clients}}
  @item{@hyperlink["https://tools.ietf.org/html/rfc7009"]{OAuth 2.0 Token Revocation}}
  @item{@hyperlink["https://tools.ietf.org/html/rfc7662"]{OAuth 2.0 Token Introspection}}
  #:style 'ordered]

In the same way as RFC6749, this implementation @italic{"defines the use of bearer
tokens over HTTP/1.1 @hyperlink["https://tools.ietf.org/html/2616"]{[RFC2616]} using
  Transport Layer Security (TLS) @hyperlink["https://tools.ietf.org/html/5246"]{[RFC5246]}
  to access protected resources."} No implementation is provided other than HTTP/1.1.

Racket already provides two packages with embedded OAuth implementations, 1)
@italic{@hyperlink["https://pkgs.racket-lang.org/package/webapi"]{webapi} -
Implementations of a few web APIs, including OAuth2, PicasaWeb, and Blogger}, and 2)
@italic{@hyperlink["https://pkgs.racket-lang.org/package/google"]{google} - Google
  APIs (Drive, Plus, ...}. The difference between these and simple-oauth2 is an
  intent to be an extensible framework that as well as providing clear
  implementations of the specific requests and the grant flows, also provides a
  credential store for client and token persistence. The package also provides example
  command-line tools for accessing common services.

@table-of-contents[]

@include-section["oauth2.scrbl"]

@include-section["client.scrbl"]

@include-section["storage.scrbl"]

@include-section["tools.scrbl"]

@section{License}

@verbatim|{|@file->string["LICENSE"]}|
