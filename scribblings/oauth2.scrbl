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
@title[]{Common Types}

This section describes the common types (structs and exceptions) across the
client and server implementations.

@;{============================================================================}
@section[]{Module oauth2.}
@defmodule[oauth2]

@defstruct[client
            ([service-name string?]
             [authorization-uri string?]
             [token-uri string?]
             [revoke-uri (or/c string? #f)]
             [introspect-uri (or/c string? #f)]
             [id (or/c string? #f)]
             [secret (or/c bytes? #f)])
            #:prefab]{
TBD
}

@defstruct[token
            ([access-token bytes?]
             [type string?]
             [refresh-token bytes?]
             [audience (or/c string? #f)]
             [scopes (listof string?)]
             [expires integer?])
            #:prefab]{
TBD
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