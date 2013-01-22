#lang racket/unit

(require drracket/tool
         framework
         gist
         racket/class
         racket/gui
         racket/list)

(import drracket:tool^)
(export drracket:tool-exports^)

(define gist-frame-mixin
  (mixin (drracket:unit:frame<%>) ()

    (inherit get-definitions-text)

    (define/override (edit-menu:between-find-and-preferences edit-menu)
      (super edit-menu:between-find-and-preferences edit-menu)
      (new menu-item%
           [label "Download gist"]
           [parent edit-menu]
           [callback (λ (i e) (do-gist this))]))

    (super-new)))

(define (do-gist frame)
  (define gist-spec (get-text-from-user "Enter gist id" "Enter gist id:"))
  (when gist-spec
    (define gist (get-gist-object (gist-spec->id gist-spec)))
    (define files (get-gist-files/dict gist))
    (define file-names (dict-keys files))
    (for ([name file-names])
      (send frame create-new-tab)
      (define tabs (send frame get-tabs))
      (define new-text (send (last tabs) get-defs))
      (send new-text insert (dict-ref files name)))))

(define (phase1) (void))
(define (phase2) (void))

(drracket:get/extend:extend-unit-frame gist-frame-mixin)
