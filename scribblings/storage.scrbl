#lang scribble/manual

@(require racket/sandbox
          scribble/core
          scribble/eval
          (for-label racket/base
                     racket/contract
                     oauth2/storage/config
                     oauth2/storage/clients
                     oauth2/storage/profiles))

@;{============================================================================}
@(define example-eval (make-base-eval
                      '(require racket/string
                                oauth2)))

@;{============================================================================}
@title[]{Configuration and Client Persistence}

@examples[ #:eval example-eval
(require oauth2/storage/config)
; add more here.
]

@;{============================================================================}
@section[]{Module oauth2/storage/config.}
@defmodule[oauth2/storage/config]

@;{============================================================================}
@section[]{Module oauth2/storage/clients.}
@defmodule[oauth2/storage/clients]

@;{============================================================================}
@section[]{Module oauth2/storage/profiles.}
@defmodule[oauth2/storage/profiles]
