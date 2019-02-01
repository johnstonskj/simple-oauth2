#lang scribble/manual

@(require racket/sandbox
          scribble/core
          scribble/eval
          (for-label racket/base
                     racket/contract
                     oauth2
                     oauth2/client
                     oauth2/client/flow))

@;{============================================================================}
@(define example-eval (make-base-eval
                      '(require racket/string
                                oauth2)))

@;{============================================================================}
@title[]{OAuth 2.0 Client}

Simple OAuth 2.0 client implementation, with a module based on the specific
and individual request/response patterns defined in the specification as well as
a higher-level module that implements end-to-end @italic{flows}.

@racketblock[
(require oauth2 oauth2/client)

(define response-channel
  (request-authorization-code
   client ; ignoring where this comes from.
   '("scope-a" "scope-b")))

(define authorization-code
  (channel-get response-channel))
(displayln (format "received auth-code ~a" authorization-code))

(when (exn:fail? authorization-code)
   (raise authorization-code))

(define token-response
  (fetch-token/from-code
   client 
   authorization-code))
(displayln (format "fetch-token/from-code returned ~a" token-response))
]

@;{============================================================================}
@section[]{Module oauth2/client.}
@defmodule[oauth2/client]


@subsection{Authorization}

@defproc[(request-authorization-code
          [client client?]
          [scopes (listof string?)]
          [#:state state #f]
          [#:challenge challenge #f]
          [#:audience audience #f])
         channel?]{
TBD

@itemlist[
  @item{@racket[client] - }
  @item{@racket[scopes] - }
  @item{@racket[state] - }
  @item{@racket[challenge] - }
  @item{@racket[audience] - }]
                   
See @hyperlink["https://tools.ietf.org/html/rfc6749#section-4.1"]{The OAuth 2.0 Authorization
  Framework}, section 4.1 and @hyperlink["https://tools.ietf.org/html/rfc7636#section-4.3"]{Proof
  Key for Code Exchange (PKCE) by OAuth Public Clients}, section 4.3.
}

@defproc[(authorization-complete)
         void?]{
TBD
}

@subsection{Authorization Token Management}

@defproc[(grant-token/from-authorization-code
          [client client?]
          [authorization-code string?]
          [#:challenge challenge #f])
         token?]{
TBD

@itemlist[
  @item{@racket[client] - }
  @item{@racket[authorization-code] - }
  @item{@racket[challenge] - }]
                   
See @hyperlink["https://tools.ietf.org/html/rfc6749#section-4.1.3"]{The OAuth 2.0 Authorization
  Framework}, section 4.1.3 and @hyperlink["https://tools.ietf.org/html/rfc7636#section-4.5"]{Proof
  Key for Code Exchange (PKCE) by OAuth Public Clients}, section 4.5.
}

@defproc[(grant-token/implicit
          [client client?]
          [scopes (listof string?)]
          [#:state state #f]
          [#:audience audience #f])
         token?]{
TBD

@itemlist[
  @item{@racket[client] - }
  @item{@racket[scopes] - }
  @item{@racket[state] - }
  @item{@racket[audience] - }]
                   
See @hyperlink["https://tools.ietf.org/html/rfc6749#section-4.2.1"]{The OAuth 2.0 Authorization
  Framework}, section 4.2.1.
}

@defproc[(grant-token/from-owner-credentials
          [client client?]
          [username string?]
          [password string?])
         token?]{
TBD

@itemlist[
  @item{@racket[client] - }
  @item{@racket[username] - }
  @item{@racket[password] - }]
                   
See @hyperlink["https://tools.ietf.org/html/rfc6749#section-4.3.2"]{The OAuth 2.0 Authorization
  Framework}, section 4.3.2.
}

@defproc[(grant-token/from-client-credentials
          [client client?])
         token?]{
TBD

@itemlist[
  @item{@racket[client] - }]
                   
See @hyperlink["https://tools.ietf.org/html/rfc6749#section-4.4.2"]{The OAuth 2.0 Authorization
  Framework}, section 4.4.2.
}

@defproc[(refresh-token
          [client client?]
          [token token?])
         token?]{
TBD

@itemlist[
  @item{@racket[client] - }
  @item{@racket[token] - }]
                   
See @hyperlink["https://tools.ietf.org/html/rfc6749#section-6"]{The OAuth 2.0 Authorization
  Framework}, section 6.
}

@defproc[(revoke-token
          [client client?]
          [token token?]
          [revoke-type string?])
         void?]{
TBD

@itemlist[
  @item{@racket[client] - }
  @item{@racket[token] - }
  @item{@racket[revoke-type] - }]
                   
See @hyperlink["https://tools.ietf.org/html/rfc7009#section-2.1"]{OAuth 2.0 Token Revocation},
  section 2.1.
}

@defproc[(introspect-token
          [client client?]
          [token token?]
          [token-type symbol?])
         hash?]{
TBD

@itemlist[
  @item{@racket[client] - }
  @item{@racket[token] - }
  @item{@racket[token-type] - }]
                   
See @hyperlink["https://tools.ietf.org/html/rfc7662#section-2.1"]{OAuth 2.0 Token Introspection},
  section 2.1.
}

@subsection{Helper Functions}

@defproc[(create-random-state
          [bytes exact-positive-integer? 16])
         string?]{
Create a random string that can be used as the @racket[state] parameter in authorization requests.
The random bytes are formatted as a byte string and safe for URL encoding.
}

@defproc[(create-pkce-challenge
          [a-verifier bytes? #f])
         pkce?]{
Create a structure that represents the components of a @italic{Proof Key for Code Exchange (PKCE)}
challenge. The @racket[a-verifier] value can be used as the seed string, if not specified a random
byte string is generated.

The following is the specified challenge construction approach from 
  @hyperlink["https://tools.ietf.org/html/rfc7636#section-4.1"]{Proof Key for Code Exchange (PKCE)
  by OAuth Public Clients}, section 4.1.

@verbatim|{
code_challenge = BASE64URL-ENCODE(SHA256(ASCII(code_verifier)))
code-verifier  = 43*128unreserved
unreserved     = ALPHA / DIGIT / "-" / "." / "_" / "~"
ALPHA          = %x41-5A / %x61-7A
DIGIT          = %x30-39}|
}

@defproc[(make-authorization-header
          [token token?])
         bytes?]{
Create a valid HTTP authorization header, as a byte string, from the provided @racket[token] value.
}

@defproc[#:kind "predicate" (pkce?
          [v any/c])
         boolean?]{
Returns @racket[#t] if the value @racket[v] is a PKCE structure (created by
  @racket[create-pkce-challenge]).
}

@;{============================================================================}
@section[]{Module oauth2/client/flow.}
@defmodule[oauth2/client/flow]

@defproc[(initiate-code-flow
          [client client?]
          [scopes (listof string?)]
          [#:user-name user-name string? #f]
          [#:state state string? #f]
          [#:challenge challenge pkce? #f]
          [#:audience audience string? #f])
         token?]{
TBD
}