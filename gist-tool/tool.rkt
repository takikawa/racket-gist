#lang racket/unit

(require drracket/tool
         data/gvector
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
           [label "Download gist..."]
           [parent edit-menu]
           [callback (λ (i e) (do-gist this))])
      (new menu-item%
           [label "Show public gists..."]
           [parent edit-menu]
           [callback (λ (i e) (show-gists this))]))

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
      (send new-text erase)
      (send new-text insert (dict-ref files name)))))

(define (show-gists frame)
  (define gists (get-public-gists))
  (define dialog (new gist-dialog%))
  (send dialog add-gists gists)
  (send dialog show #t))

;; dialog% for displaying gists
(define gist-dialog%
  (class dialog%
    (super-new [label "Public gists"])

    ;; to contain the editors for each gist
    (define panel (new vertical-panel% [parent this]))
    (define main-editor (new text:basic% [auto-wrap #t]))
    (define main-ec (new editor-canvas%
                         [parent panel]
                         [editor main-editor]
                         [style '(no-hscroll)]
                         [stretchable-width #t]))

    ;; snips for each gist
    (define snips (gvector))

    ;; display a list of gists
    (define/public (add-gists lst-of-gists)
      (for ([gist (in-list lst-of-gists)])
        (add-gist gist)))

    ;; add a gist to the dialog
    (define (add-gist gist-json)
      (define gist-text (new text:basic% [auto-wrap #t]))
      (define snip (new editor-snip% [editor gist-text]))
      (gvector-add! snips snip)
      (send main-editor insert snip)
      (send main-editor insert "\n")
      (define description
        (let ([elem (dict-ref gist-json 'description)])
          (if (or (eq? 'null elem) (string=? "" elem))
              "No description provided"
              elem)))
      (send gist-text insert (dict-ref gist-json 'id))
      (send gist-text insert "\n")
      (send gist-text insert description)
      (send gist-text lock #t))

    (define/override (on-size width height)
      (for ([snip (in-gvector snips)])
        (send snip set-max-width width)
        (send snip set-max-height height)))))

;; Tool setup
(define (phase1) (void))
(define (phase2) (void))

(drracket:get/extend:extend-unit-frame gist-frame-mixin)
