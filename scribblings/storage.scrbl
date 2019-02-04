#lang scribble/manual

@(require racket/sandbox
          scribble/core
          scribble/eval
          (for-label racket/base
                     racket/contract
                     oauth2
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

This module provides a very simple get/put interface for configuration settings
used by the package in general. The following table describes the currently used
settings, with their types and default values.

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

The values for @racket['cipher-impl], @racket['cipher-key], and @racket['cipher-iv]
should not be modified by hand. The @racket['cipher-impl] value determines which
implementation is used to generate the @racket['cipher-key] and @racket['cipher-iv]
which are used to encrypt/decrypt secrets in the @tt{clients} and @tt{tokens} files.

The values starting with @racket['redirect-] represent the configuration for the
internal web server required to host the OAuth redirect URI. The two SSL settings
are paths to the corresponding files containing the certificate and key.

@deftogether[(
  @defproc[(get-current-user-name) string?]
  @defproc[(get-current-user-name/bytes) bytes?])]{
Retrieve the user name for the currently logged-in user, this is used by default as
the @italic{on-belhalf-of} user in authentication calls.
}

@defproc[(get-preference
          [key symbol?]) any/c]{
Retrieve a preference value using one of the symbols listed in the table above.
}

@defproc[(set-preference!
          [key symbol?]
          [value any/c]) void/c]{
Set a preference value for one of the keys listed in the table above.
}

@deftogether[(@defproc[(load-preferences) boolean?]
              @defproc[(save-preferences) boolean?])]{
Load and save the preference file, by default a file is loaded when the module
is imported for the first time. If no file is found a new one is created with
the default values listed in the table above.
}



@;{============================================================================}
@section[]{Module oauth2/storage/clients.}
@defmodule[oauth2/storage/clients]

This module provides a persistence layer for client configurations (see struct
@racket[client?]). The value for @racket[client-secret] will be encryted during
@racket[set-client!] and decrypted during @racket[get-client] and therefore will
alway be stored in encrypted form.

@defproc[(get-client
          [service-name string?]) client?]{
Retrieve a client configuration from it's service name. 
}

@defproc[(set-client!
          [a-client clientl?]) void/c]{
Store a client configuration as a mapping from service name (see
@racket[client-service-name] to client.
                                                                 
}

@deftogether[(@defproc[(load-clients) boolean?]
              @defproc[(save-clients) boolean?])]{
Load and save the clients file, by default a file is loaded when the module
is imported for the first time.
}

@;{============================================================================}
@section[]{Module oauth2/storage/tokens.}
@defmodule[oauth2/storage/tokens]

This module provides a persistence layer for authentication tokens (see struct
@racket[token?]). The values for @racket[token-access-token] and
@racket[token-refresh-token] will be encryted during @racket[set-token!] and
decrypted during @racket[get-token] and therefore will alway be stored in
encrypted form.

@defproc[(get-services-for-user
          [user-name string?]) (listof string?)]{
Retrieve a list of service names that have tokens for the given
user name.
}

@defproc[(get-token
          [user-name string?]
          [service-name string?]) token?]{
Retrieve a token retrieved from @racket[service-name], on behalf of the user
@racket[user-name].
}

@defproc[(set-token!
          [user-name string?]
          [service-name string?]
          [a-token token?]) void/c]{
Store a token retrieved from @racket[service-name], on behalf of the user
@racket[user-name].
}

@deftogether[(@defproc[(load-tokens) boolean?]
              @defproc[(save-tokens) boolean?])]{
Load and save the tokens file, by default a file is loaded when the module
is imported for the first time.
}

