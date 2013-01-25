#lang racket/base

(require json
         net/url
         racket/contract
         racket/dict
         racket/list
         racket/port
         rackunit
         wffi/client
         wffi/markdown
         (for-syntax racket/base
                     racket/runtime-path
                     wffi/markdown))

(provide
 (contract-out
  [get-gist-object (-> gist-id/c jsexpr?)]
  [get-gist-files (-> jsexpr? (listof string?))]
  [get-gist-files/dict (-> jsexpr? (hash/c string? string?))]
  [get-public-gists (-> (listof jsexpr?))]
  [gist-spec? (-> any/c boolean?)]
  [gist-spec->id (-> gist-spec? gist-id/c)]))

(define pre values)

;; define the runtime path for use at phase 1
(module path racket/base
  (require racket/runtime-path)

  (define-runtime-path here ".")
  (provide here))

;; make sure gist.md can be found
(require 'path (for-syntax 'path))

(begin-for-syntax
  (current-markdown-files-path here))
(current-markdown-files-path here)

(wffi-define-all "gist.md" pre check-response/json)

;; returns the JSON object for a gist
(define (get-gist-object id)
  ;; TODO: error checking
  (get-single-gist 'id id))

;; returns a list of gist contents
(define (get-gist-files gist-js)
  (get-gist-files/core gist-js))

;; returns a dictionary of file names to contents
(define (get-gist-files/dict gist-js)
  (get-gist-files/core gist-js #t))

;; returns gist contents (in dict or list)
(define (get-gist-files/core gist-js [dict? #f])
  ;; download contents for a file
  (define (retrieve-contents file-js)
    (define url (string->url (dict-ref file-js 'raw_url)))
    (define in (get-pure-port url))
    (define contents (port->string in))
    (close-input-port in)
    contents)
  (define files (dict-ref gist-js 'files))
  (if dict?
      (for/hash ([file (in-hash-values files)])
        (values
         (dict-ref file 'filename)
         (retrieve-contents file)))
      (for/list ([file (in-hash-values files)])
        (retrieve-contents file))))

;; retrieve a list of public gist objects
(define (get-public-gists)
  (list-public-gists))

;; Utilities and contracts

(define gist-id/c
  (flat-named-contract 'gist-id exact-nonnegative-integer?))

;; return #t if the given string can be
;; interpreted as a URL to a gist or a gist id
(define (gist-spec? str)
  (cond [(string->number str)
         =>
         (λ (n) (exact-integer? n))]
        [(string->url str)
         =>
         (λ (url)
           (and (equal? (url-host url) "gist.github.com")
                (not (empty? (url-path url)))
                (let ([path (path/param-path (first (url-path url)))])
                  (and (string? path)
                       (regexp-match-exact? #px"\\d+" path)))))]))

;; gist-spec? -> gist-id/c
;; turn a spec into an id
(define (gist-spec->id str)
  (or (string->number str)
      (let* ([url (string->url str)]
             [path (path/param-path (car (url-path url)))])
        (string->number
         (first
          (regexp-match* #px"^\\d+$" path))))))

(module+ test
  (check-true (gist-spec? "http://gist.github.com/1123"))
  (check-true (gist-spec? "https://gist.github.com/1123"))
  (check-false (gist-spec? "http://www.github.com/1123"))
  (check-false (gist-spec? "http://gist.github.com/foo/bar/1123"))
  (check-false (gist-spec? "http://gist.github.com/foobar"))
  (check-true (gist-spec? "1234235"))
  (check-true (gist-spec? "44235"))
  (check-false (gist-spec? "44235.53"))
  (check-false (gist-spec? "44235/3243"))

  (check-equal? (gist-spec->id "http://gist.github.com/1123")
                1123)
  (check-equal? (gist-spec->id "https://gist.github.com/1123")
                1123)
  (check-equal? (gist-spec->id "1234235") 1234235)
  (check-equal? (gist-spec->id "44235") 44235))
