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
See @hyperlink["https://tools.ietf.org/html/rfc6749#section-4.1"]{The OAuth 2.0 Authorization
  Framework}, section 4.1 and @hyperlink["https://tools.ietf.org/html/rfc7636#section-4.3"]{Proof
  Key for Code Exchange (PKCE) by OAuth Public Clients}, section 4.3.
}

@defproc[(authorization-complete)
         void?]{
TBD
}

@subsection{Authorization Token Management}

@defproc[(fetch-token/from-code
          [client client?]
          [authorization-code string?]
          [#:challenge challenge #f])
         token?]{
See @hyperlink["https://tools.ietf.org/html/rfc6749#section-4.1.3"]{The OAuth 2.0 Authorization
  Framework}, section 4.1.3 and @hyperlink["https://tools.ietf.org/html/rfc7636#section-4.5"]{Proof
  Key for Code Exchange (PKCE) by OAuth Public Clients}, section 4.5.
}

@defproc[(fetch-token/implicit
          [client client?]
          [scopes (listof string?)]
          [#:state state #f]
          [#:audience audience #f])
         token?]{
See @hyperlink["https://tools.ietf.org/html/rfc6749#section-4.2.1"]{The OAuth 2.0 Authorization
  Framework}, section 4.2.1.
}

@defproc[(fetch-token/with-password
          [client client?]
          [username string?]
          [password string?])
         token?]{
See @hyperlink["https://tools.ietf.org/html/rfc6749#section-4.3.2"]{The OAuth 2.0 Authorization
  Framework}, section 4.3.2.
}

@defproc[(fetch-token/with-client
          [client client?])
         token?]{
See @hyperlink["https://tools.ietf.org/html/rfc6749#section-4.4.2"]{The OAuth 2.0 Authorization
  Framework}, section 4.4.2.
}

@defproc[(refresh-token
          [client client?]
          [token token?])
         token?]{
See @hyperlink["https://tools.ietf.org/html/rfc6749#section-6"]{The OAuth 2.0 Authorization
  Framework}, section 6.
}

@defproc[(revoke-token
          [client client?]
          [token token?]
          [revoke-type string?])
         void?]{
See @hyperlink["https://tools.ietf.org/html/rfc7009#section-2.1"]{OAuth 2.0 Token Revocation},
  section 2.1.
}

@defproc[(introspect-token
          [client client?]
          [token token?]
          [token-type symbol?])
         hash?]{
See @hyperlink["https://tools.ietf.org/html/rfc7662#section-2.1"]{OAuth 2.0 Token Introspection},
  section 2.1.
}

@subsection{Helper Functions}

@defproc[(create-random-state
          [bytes integer? 16])
         string?]{
TBD
}

@defproc[(create-pkce-challenge
          [a-verifier bytes? #f])
         pkce?]{
See @hyperlink["https://tools.ietf.org/html/rfc7636#section-4.1"]{Proof Key for Code Exchange (PKCE)
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
TBD
}

@defproc[#:kind "predicate" (pkce?
          [v any/c])
         boolean?]{
TBD
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