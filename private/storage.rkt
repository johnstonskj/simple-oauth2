#lang racket/base
;;
;; simple-oauth2 - oauth/private/storage.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

;; Racket Style Guide: http://docs.racket-lang.org/style/index.html

(require racket/contract)

(provide
 (all-defined-out))

;; ---------- Requirements

(require (for-syntax
          racket/base
          racket/class
          racket/list
          racket/path
          racket/sequence
          racket/syntax))

;; ---------- Implementation (file handling)

(define-syntax (define-cached-file stx)
  (syntax-case stx ()
    [(_ id root path)
     (and (identifier? #'id)
          (string? (syntax->datum #'path)))
     #`(define-cached-file id root path #,(symbol->string (syntax->datum #'id)) #f)]
    [(_ id root path file-name predicate)
     (and (identifier? #'id)
;          (or (string? (syntax->datum #'root)) (symbol? (syntax->datum #'root)))
          (string? (syntax->datum #'path))
          (string? (syntax->datum #'file-name)))
;          (procedure? (syntax->datum #'predicate)))
     (with-syntax ([cache (format-id #'id "~a-cache" #'id)]
                   [loader (format-id #'id "load-~a" #'id)]
                   [saver (format-id #'id "save-~a" #'id)]
                   [file-path (format-id #'id "get-~a-file-path" #'id)])
       #`(begin
           (require racket/file)
           (define cache (make-hash))
           (define (saver)
             (define save-path (file-path))
             (when (file-exists? save-path)
               (rename-file-or-directory save-path (path-add-extension save-path ".last")))
             (call-with-output-file save-path
               (lambda (out)
                 (write cache out)))
             #t)
           (define (loader) 
             (define load-path (file-path))
               (when (file-exists? load-path)
               (call-with-input-file load-path
                 (lambda (in)
                   (define value (read in))
                   (cond
                     [(hash? value)
                      (set! cache value)]
                     [else (error "value read was not a hash: " value)]))))
             #t)
           (define (file-path)
             (define dir-path 
               (build-path 
                 (cond
                  [(string? root)
                   (string->path root)]
                  [(symbol? root)
                   (find-system-path 'home-dir)]
                  [else (error "invalid file path root")])
                 path))
             (make-directory* dir-path)
             (build-path dir-path file-name))

       ))]))
