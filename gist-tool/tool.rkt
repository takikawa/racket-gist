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
    (define panel (new vertical-panel%
                       [parent this]
                       [style '(vscroll)]))

    ;; display a list of gists
    (define/public (add-gists lst-of-gists)
      (for ([gist (in-list lst-of-gists)])
        (add-gist gist)))

    ;; add a gist to the dialog
    (define (add-gist gist-json)
      (new gist%
           [gist-json gist-json]
           [parent panel]))))

;; for displaying a single gist in the list view
;; Note: only displays correctly in 5.3.2.2 and up
(define gist%
 (class group-box-panel%
   (init parent)
   (init-field gist-json)
   (super-new [label (string-append "gist id: "
                                    (dict-ref gist-json 'id))]
              [parent parent])

   (define gist-text (new text:hide-caret/selection%
                          [auto-wrap #t]))
   (define canvas (new editor-canvas%
                       [parent this]
                       [style '(no-border no-hscroll
                                no-vscroll transparent)]
                       [editor gist-text]))
   (define description
     (let ([elem (dict-ref gist-json 'description)])
       (if (or (eq? 'null elem) (string=? "" elem))
           "No description provided"
           elem)))
   (send gist-text insert description)
   (send gist-text hide-caret #t)
   (send gist-text lock #t)

   ;; make sure canvas is as large as needed for text
   (define line-padding 2)
   (send canvas set-line-count
         (+ line-padding (send gist-text last-line)))))

;; Tool setup
(define (phase1) (void))
(define (phase2) (void))

(drracket:get/extend:extend-unit-frame gist-frame-mixin)
