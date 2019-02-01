#lang scribble/manual

@(require racket/sandbox
          scribble/core
          scribble/eval
          (for-label racket/base
                     racket/contract
                     oauth2/storage/config
                     oauth2/storage/clients
                     oauth2/storage/tokens))

@;{============================================================================}
@(define example-eval (make-base-eval
                      '(require racket/path
                                racket/string
                                oauth2)))

@;{============================================================================}
@title[]{Configuration and Client Persistence}

The three modules described here allow the persistence of configuration between
execution of tools or services using this package.


By default the files described below are stored in a directory @italic{".oauth2.rkt"}
within the directory specified by @racket[find-system-path] with the @italic{kind}
value @racket['home-dir].

@;{============================================================================}
@section[]{Module oauth2/storage/config.}
@defmodule[oauth2/storage/config]

@tabular[#:style 'boxed
         #:row-properties '(bottom-border ())
         (list (list @bold{key}   @bold{type} @bold{default value})
               (list @racket['cipher-impl] @racket[(listof symbol?)] @racket['(aes gcm)])
               (list @racket['cipher-key] @racket[bytes?] @italic{generated})
               (list @racket['cipher-iv] @racket[bytes?] @italic{generated})
               (list @racket['redirect-host-type] @racket[symbol?] @racket['localhost])
               (list @racket['redirect-host-port] @racket[exact-positive-integer?] @racket[8080])
               (list @racket['redirect-path] @racket[string?] @racket["/oauth/authorization"])
               (list @racket['redirect-ssl-certificate] @racket[(or/c false/c path-string?)] @racket[#f])
               (list @racket['redirect-ssl-key] @racket[(or/c false/c path-string?)] @racket[#f]))]

@deftogether[(
  @defproc[(get-current-user-name) string?]
  @defproc[(get-current-user-name/bytes) bytes?])]{
TBD
}

@defproc[(get-preference
          [key symbol?]) any/c]{
TBD
}

@defproc[(set-preference!
          [key symbol?]
          [value any/c]) void/c]{
TBD
}

@defproc[(load-preferences) boolean?]{TBD}

@defproc[(save-preferences) boolean?]{TBD}



@;{============================================================================}
@section[]{Module oauth2/storage/clients.}
@defmodule[oauth2/storage/clients]

@;{============================================================================}
@section[]{Module oauth2/storage/tokens.}
@defmodule[oauth2/storage/tokens]
