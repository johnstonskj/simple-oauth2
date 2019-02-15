#lang scribble/manual

@(require racket/sandbox
          scribble/core
          scribble/eval
          (for-label racket/base
                     racket/contract
                     json
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

This module provides request-level procedures that match the sections of the
OAuth specification. While each provides a reasonable interface abstraction
there remains a 1:1 mapping from the procedures here and the specific HTTP requests
described in the corresponding RFCs.

@subsection{Authorization}

@defproc[(request-authorization-code
          [client client?]
          [scopes (listof string?)]
          [#:state state #f]
          [#:challenge challenge #f]
          [#:audience audience #f])
         channel?]{
Given a client configuration, and a list of requested scopes, request an
authorization code by having the user complete a manual authentication and
authorization step via the URI in @racket[client-authorization-uri]. This is
an asynchronous process directing the user to a web page provided by the
service to authenticate the request. Upon success the users browser is
redirected to a page hosted by this package (the @italic{redirect server}).
To address this, the response from this procedure is a @racket[channel] which
will be to communicate back to the caller the authorization code provided by
the service via the redirect server. See
@hyperlink["https://tools.ietf.org/html/rfc6749#section-4.1"]{The OAuth 2.0
Authorization Framework}, §4.1

@itemlist[
  @item{@racket[client] - the client configuration for the service performing
  the authorization.}
  @item{@racket[scopes] - a set of scopes to which we are requesting access.}
  @item{@racket[state] - (optional) a state value, returned to the redirect
  server for request/response correlation.}
  @item{@racket[challenge] - (optional) a PKCE challenge structure, if @racket[#f]
  PKCE @italic{will not} be used. See @hyperlink["https://tools.ietf.org/html/rfc7636#section-4.3"]{Proof
  Key for Code Exchange (PKCE) by OAuth Public Clients}, §4.3.}
  @item{@racket[audience] - (optional) a non-standard value used by some services
  to denote the API set to which access is requested. if @racket[#f]
  this parameter @italic{will not} be sent.}]

The value read from the response channel will either be a @racket[string?] code or
an exception (@racket[exn:fail:http] or @racket[exn:fail:oauth2]). The authorization
code read from the response channel may then be used in a call to
@racket[grant-token/from-authorization-code] to retieve a token for this client.
}

@defproc[(authorization-complete)
         void?]{
The redirect server used in the retrieval of authorization codes utilizes a
set of asynchronous resources including blocking threads. These resources
are only started when a client calls @racket[request-authorization-code] for
the first time but then they remain in place until the process is terminated
or they are shut down explicitly. This procedure performs an orderly shut down
of the redirect server.
}

@subsection{Authorization Token Management}

@defproc[(grant-token/from-authorization-code
          [client client?]
          [authorization-code string?]
          [#:challenge challenge #f])
         token?]{
Request the authorization server grant an access token (and usually a refresh token also) given an
authorization code previously provided by @racket[request-authorization-code].

From @hyperlink["https://tools.ietf.org/html/rfc6749#section-4.1.3"]{The OAuth 2.0 Authorization
  Framework}, §4.1.3: @emph{The authorization code grant type is used to obtain both access
   tokens and refresh tokens and is optimized for confidential clients.
   Since this is a redirection-based flow, the client must be capable of
   interacting with the resource owner's user-agent (typically a web
   browser) and capable of receiving incoming requests (via redirection)
   from the authorization server.}

@itemlist[
  @item{@racket[client] - the client configuration for the service granting
  the token(s).}
  @item{@racket[authorization-code] - a valid authorization code.}
  @item{@racket[challenge] - (optional) a PKCE challenge structure, if @racket[#f]
  PKCE @italic{will not} be used. See
   @hyperlink["https://tools.ietf.org/html/rfc7636#section-4.5"]{Proof
   Key for Code Exchange (PKCE) by OAuth Public Clients}, §4.5.}]
}

@defproc[(grant-token/implicit
          [client client?]
          [scopes (listof string?)]
          [#:state state #f]
          [#:audience audience #f])
         token?]{
From @hyperlink["https://tools.ietf.org/html/rfc6749#section-4.2.1"]{The
OAuth 2.0 Authorization Framework}, §4.2.1:
@emph{The implicit grant type is used to obtain access tokens (it does not
   support the issuance of refresh tokens) and is optimized for public
   clients known to operate a particular redirection URI. ... 

Unlike the authorization code grant type, in which the client makes
   separate requests for authorization and for an access token, the
   client receives the access token as the result of the authorization
   request.}

@itemlist[
  @item{@racket[client] - the client configuration for the service performing
  the authorization.}
  @item{@racket[scopes] - a set of scopes to which we are requesting access.}
  @item{@racket[state] - (optional) a state value, returned to the redirect
  server for request/response correlation.}
  @item{@racket[audience] - (optional) a non-standard value used by some services
  to denote the API set to which access is requested. if @racket[#f]
  this parameter @italic{will not} be sent.}]
}

@defproc[(grant-token/from-owner-credentials
          [client client?]
          [username string?]
          [password string?])
         token?]{
From @hyperlink["https://tools.ietf.org/html/rfc6749#section-4.3.2"]{The OAuth 2.0 Authorization
  Framework}, §4.3.2:
@emph{The resource owner password credentials grant type is suitable in
   cases where the resource owner has a trust relationship with the
   client, such as the device operating system or a highly privileged
   application. ...

This grant type is suitable for clients capable of obtaining the
   resource owner's credentials (username and password, typically using
   an interactive form).  It is also used to migrate existing clients
   using direct authentication schemes such as HTTP Basic or Digest
   authentication to OAuth by converting the stored credentials to an
   access token.}

@itemlist[
  @item{@racket[client] - the client configuration for the service performing
  the authorization.}
  @item{@racket[username] - the name of the resource owner being authorized.}
  @item{@racket[password] - the password for the resource owner being authorized.}]
}

@defproc[(grant-token/from-client-credentials
          [client client?])
         token?]{
From @hyperlink["https://tools.ietf.org/html/rfc6749#section-4.4.2"]{The OAuth 2.0 Authorization
  Framework}, §4.4.2:
@emph{The client can request an access token using only its client
  credentials (or other supported means of authentication) when the
  client is requesting access to the protected resources under its
  control, or those of another resource owner that have been previously
  arranged with the authorization server (the method of which is beyond
  the scope of this specification).}

@itemlist[
  @item{@racket[client] - the client configuration for the service performing
  the authorization.}]
}

@defproc[(grant-token/extension
          [client client?]
          [grant-type-urn string?]
          [parameters (hash/c symbol? string?) (hash)])
         token?]{
From @hyperlink["https://tools.ietf.org/html/rfc6749#section-4.5"]{The OAuth 2.0 Authorization
  Framework}, §4.5: @emph{The client uses an extension grant type by specifying the grant type
  using an absolute URI (defined by the authorization server) as the
  value of the "grant_type" parameter of the token endpoint, and by
  adding any additional parameters necessary.} 

Note that the @racket[grant-type-urn] @bold{should} be a registered IETF value
according to @hyperlink["https://tools.ietf.org/html/rfc6755"]{An IETF URN Sub-Namespace for OAuth},
but the only validation the client performs is that it starts with the prefix
value @racket[oauth-grant-type-urn].

@itemlist[
  @item{@racket[client] - the client configuration for the service performing
  the authorization.}
  @item{@racket[grant-type-urn] - the absolute URI (actually verifies it as a URN)
   that identifies the @tt{grant_type} extension.}
  @item{@racket[parameters] - (optional) a mapping of symbols that represent grant
   parameter names and string values.}]

@bold{Example SAML 2.0 extension}

@racketblock[
(grant-token/extension
 client
 "urn:ietf:params:oauth:grant_type:saml2-bearer"
 (hash 'assertion "PEFzc2VydGlvbiBJc3N1ZUluc3RhbnQ9Ij...IwMTEtMDU"))
]
}

@deftogether[(
              @defthing[oauth-namespace-urn string?]
              @defthing[oauth-grant-type-urn string?])]{
These values represent the IETF registered URN prefixes for extension values
used to add methods to OAuth. See @racket[grant-token/extension].
}


@defproc[(refresh-token
          [client client?]
          [token token?])
         token?]{
@emph{Access tokens} are returned to the client along with an expiration duration, thus
they periodically become unusable when they expire. If the authorization server
also provided a @emph{refresh token} it may be used to generate a new access token, with
a new expiration duration.

From @hyperlink["https://tools.ietf.org/html/rfc6749#section-6"]{The OAuth 2.0 Authorization
  Framework}, §6: @emph{If the authorization server issued a refresh token to the client, the
  client makes a refresh request to the token endpoint}. Note that the token endpoint is the
  same used for access grants above.

@itemlist[
  @item{@racket[client] - the client configuration for the service performing
  the authorization.}
  @item{@racket[token] - the token structure, the @racket[token-refresh-token] value
   will be used to generate a new @racket[token-access-token] value.}]
}

@defproc[(revoke-token
          [client client?]
          [token token?]
          [token-type-hint string? #f])
         void?]{
From @hyperlink["https://tools.ietf.org/html/rfc7009#section-2.1"]{OAuth 2.0 Token Revocation},
  §2.1:
@emph{The OAuth 2.0 core specification [RFC6749] defines several ways for a
   client to obtain refresh and access tokens.  This specification
   supplements the core specification with a mechanism to revoke both
   types of tokens.  A token is a string representing an authorization
   grant issued by the resource owner to the client.  A revocation
   request will invalidate the actual token and, if applicable, other
   tokens based on the same authorization grant and the authorization
   grant itself.}
   
@emph{Implementations MUST support the revocation of refresh tokens and
   SHOULD support the revocation of access tokens}

@itemlist[
  @item{@racket[client] - the client configuration for the service performing
  the authorization.}
  @item{@racket[token] - the token to revoke.}
  @item{@racket[token-type-hint] - (optional) determines the type of token to send to the server.
   One of @racket['access-token] or @racket['refresh-token].}]
}

@defproc[(introspect-token
          [client client?]
          [token token?]
          [token-type-hint symbol?])
         jsexpr?]{

From @hyperlink["https://tools.ietf.org/html/rfc7662#section-2.1"]{OAuth 2.0 Token Introspection},
  §2.1: @emph{This specification defines a protocol that allows authorized
   protected resources to query the authorization server to determine
   the set of metadata for a given token that was presented to them by
   an OAuth 2.0 client.  This metadata includes whether or not the token
   is currently active (or if it has expired or otherwise been revoked),
   what rights of access the token carries (usually conveyed through
   OAuth 2.0 scopes), and the authorization context in which the token
   was granted (including who authorized the token and which client it
   was issued to).  Token introspection allows a protected resource to
   query this information regardless of whether or not it is carried in
   the token itself, allowing this method to be used along with or
   independently of structured token values.  Additionally, a protected
   resource can use the mechanism described in this specification to
   introspect the token in a particular authorization decision context
   and ascertain the relevant metadata about the token to make this
   authorization decision appropriately.}

@itemlist[
  @item{@racket[client] - the client configuration for the service performing
  the authorization.}
  @item{@racket[token] - the token to introspect.}
  @item{@racket[token-type-hint] - (optional) determines the type of token to send to the server.
   One of @racket['access-token] or @racket['refresh-token].}]
}

@subsection{Resource Access}

@defproc[(resource-sendrecv
          [resource-uri string?]
          [token token?]
          [#:method method string? "GET"]
          [#:headers headers (listof bytes?) '()]
          [#:data data (or/c bytes? #f) #f])
         list?]{
Make a request to a resource server, protected by @racket[token], and return the result. The
results are in the form of a four-part list @italic{(http-code http-message response-headers
response-body)}.
}

@defproc[(make-authorization-header
          [token token?])
         bytes?]{
Create a valid HTTP authorization header, as a byte string, from the provided @racket[token] value.
See @hyperlink["https://tools.ietf.org/html/rfc7662#section-7.1"]{OAuth 2.0 Token Introspection},
  §7.1:
}

@subsection{Parameter Creation}

@defproc[(create-random-state
          [bytes exact-positive-integer? 16])
         string?]{
Create a random string that can be used as the @racket[state] parameter in authorization requests.
The random bytes are formatted as a byte string and safe for URL encoding.
}

@subsection{Response Error Handling}

@defproc[(register-error-transformer
          [url string?]
          [func (-> string? jsexpr? continuation-mark-set? (or/c exn:fail:oauth2 #f))])
         void?]{
Specifically for services that do not follow the standard error response format in
@hyperlink["https://tools.ietf.org/html/rfc6749#section-4.1.2.1"]{The OAuth 2.0 Authorization
Framework}, §4.1.2.1 (or other sections titled Error Response). A client may register an
error transformer that will be passed any non-standard JSON error responses from calls to
the registered URL, to transform into an @racket[exn:fail:oauth2] exception.
            
@racketblock[
(define (fitbit-error-handler uri json-body cm)
  (cond
    [(hash-has-key? json-body 'errors)
     (define json-error (first (hash-ref json-body 'errors '())))
     (make-exn:fail:oauth2 (hash-ref json-error 'errorType 'unknown)
                           (hash-ref json-error 'message "")
                           uri
                           "" ; unknown state
                           cm)]
    [else #f]))

(register-error-transformer
 (client-authorization-uri fitbit-client)
 fitbit-error-handler)
]
}

@defproc[(deregister-error-transformer[url string?]) void?]{
This procedure removes any error transformer associated with @racket[url].
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

@itemlist[
  @item{@racket[client] - the client configuration for the service performing
  the authorization.}
  @item{@racket[scopes] - a set of scopes to which we are requesting access.}
  @item{@racket[state] - (optional) a state value, returned to the redirect
  server for request/response correlation.}
  @item{@racket[user-name] - (optional) the user name to record the token under; if
  @racket[#f] then the value of @racket[get-current-user-name] will be used.}
  @item{@racket[challenge] - (optional) a PKCE challenge structure, if @racket[#f]
  PKCE @italic{will not} be used.}
  @item{@racket[audience] - (optional) a non-standard value used by some services
  to denote the API set to which access is requested. if @racket[#f]
  this parameter @italic{will not} be sent.}]
}

@;{============================================================================}
@section[]{Module oauth2/client/pkce.}
@defmodule[oauth2/client/pkce]

This module simply provides the constructor for challenge values as specified in 
@hyperlink["https://tools.ietf.org/html/rfc7636"]{RFC7636 - Proof Key for Code
Exchange (PKCE) by OAuth Public Clients}. PKCE structures may be used in the
@racket[request-authorization-code] and @racket[grant-token/from-authorization-code]
procedures.

@defstruct[pkce ([verifier bytes?]
                 [challenge string?]
                 [method (or/c "plain" "S256")]) #:omit-constructor ]{
Values of @racket[pkce?] are constructed only by @racket[create-challenge] (there is
no @tt{make-pkce} procedure) and represent the PKCE challenge details.
}

@defproc[(create-challenge
          [a-verifier bytes? #f])
         pkce?]{
Create a structure that represents the components of a PKCE
challenge. The @racket[a-verifier] value (defined as a @emph{high-entropy cryptographic
random STRING}) can be used as the seed string, if not specified a random
byte string is generated.

The following is the specified challenge construction approach from 
@hyperlink["https://tools.ietf.org/html/rfc7636#section-4.1"]{RFC7636}, §4.1.

@verbatim|{
code_challenge = BASE64URL-ENCODE(SHA256(ASCII(code_verifier)))
code-verifier  = 43*128unreserved
unreserved     = ALPHA / DIGIT / "-" / "." / "_" / "~"
ALPHA          = %x41-5A / %x61-7A
DIGIT          = %x30-39}|

Also, note that while the value @tt{"plain"} is a valid @racket[method] according to the PKCE RFC
@bold{at this time} it is not used in this implementation, @bold{only} the value
@tt{"S256"} will be used.
}

@defproc[(verifier-char? [ch any?]) boolean?]{
Implements the @tt{unreserved} rule from the construction rules above.
}

