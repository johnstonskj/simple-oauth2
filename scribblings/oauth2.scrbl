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
@title[]{Common Definitions}

This section describes the common constants, structs, and exceptions across both
the client and server implementations.

@;{============================================================================}
@section[]{Module oauth2.}
@defmodule[oauth2]

@defthing[OAUTH-SPEC-VERSION number? #:value 2.0]{
The current OAuth specification version supported by the package.
}

@defthing[OAUTH-RFC exact-positive-integer? #:value 6749]{
The current OAuth specification RFC supported by the package.
}

@defthing[OAUTH-DISPLAY-NAME string? #:value "OAuth {{version}} (RCF{{rfc}})"]{
A display string formatting the version of OAuth supported by the package.
}

@deftogether[(@defthing[oauth2-logger logger?]
              @defform*[((log-oauth2-debug string-expr)
                         (log-oauth2-debug format-string-expr v ...))]
              @defform*[((log-oauth2-info string-expr)
                         (log-oauth2-info format-string-expr v ...))]
              @defform*[((log-oauth2-warning string-expr)
                         (log-oauth2-warning format-string-expr v ...))]
              @defform*[((log-oauth2-error string-expr)
                         (log-oauth2-error format-string-expr v ...))]
              @defform*[((log-oauth2-fatal string-expr)
                         (log-oauth2-fatal format-string-expr v ...))])]{
The logger instance, and logging procedures, used internally by the package. This is
provided for tools to be ablt to log OAuth specific interactions with the same topic,
but also to adjust the level of logging performed by the library.
}


@subsection{Structure Types}

@defstruct[client
            ([service-name string?]
             [authorization-uri string?]
             [token-uri string?]
             [revoke-uri (or/c string? #f)]
             [introspect-uri (or/c string? #f)]
             [id (or/c string? #f)]
             [secret (or/c bytes? #f)])
            #:prefab]{
This is the basic details of a registered client for an OAuth protected resource server
where @racket[service-name] is the display name for the service. Both @racket[authorization-uri]
and @racket[token-uri] are required values and are the published endpoints.

The @racket[id] and @racket[secret] are the values provided by the service to you, the client,
for authentication. The client id should uniquely identify your client and the secret is
used in certain token grant flows. Note that the @racket[secret] value should @bold{always} be stored
securely, see @secref["Module_oauth2_storage_clients_"
                      #:doc '(lib "oauth2/scribblings/simple-oauth2.scrbl")] for details on
persistence of client details.

The @racket[revoke-uri] and @racket[introspect-uri] fields are both optional as it may be that
the service does not support revoking or introspecting tokens.
}

@defstruct[token
            ([access-token bytes?]
             [type string?]
             [refresh-token bytes?]
             [audience (or/c string? #f)]
             [scopes (listof string?)]
             [expires exact-positive-integer?])
            #:prefab]{
This represents the details of tokens granted by the service to your client.

The value of @racket[expires] denotes the time, in seconds, at which the @racket[access-token]
will expire and no longer be valid for use. This is stored as an absolute value so that the
@italic{is expired?} test is simply:

@racketblock[
(define (token-expired? t)
  (> (current-seconds) (token-expires t)))
]

Note that the @racket[access-token] and @racket[refresh-token] values should @bold{always} be stored
securely, see  @secref["Module_oauth2_storage_tokens_"
                       #:doc '(lib "oauth2/scribblings/simple-oauth2.scrbl")] for details on
persistence of token details.
}

@subsection{Exceptions}

@defstruct[(exn:fail:http exn:fail)
            ([code integer?]
             [headers list?]
             [body bytes?])
            #:transparent]{
TBD
}

@defstruct[(exn:fail:oauth2 exn:fail)
            ([error symbol?]
             [error-uri (or/c string? #f)]
             [state (or/c string? #f)])
            #:transparent]{
TBD
}

@defproc[(exn:fail:oauth2-error-description
          [exn exn:fail:oauth2?])
         string?]{
TBD
}