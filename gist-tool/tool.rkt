#lang racket/unit

(require drracket/tool
         data/gvector
         framework
         gist
         net/sendurl
         racket/class
         racket/gui
         racket/list)

(import drracket:tool^)
(export drracket:tool-exports^)

(define gist-frame-mixin
  (mixin (drracket:unit:frame<%>) ()

    (inherit get-definitions-text)

    (define/override (file-menu:between-open-and-revert file-menu)
      (super file-menu:between-open-and-revert file-menu)
      (new menu-item%
           [label "Download gist..."]
           [parent file-menu]
           [callback (λ (i e) (do-gist this))])
      (new menu-item%
           [label "Show public gists..."]
           [parent file-menu]
           [callback (λ (i e) (show-gists this))])
      (new separator-menu-item% [parent file-menu]))

    (super-new)))

(define (do-gist frame [gist-object #f])
  (define gist-spec
    (and (not gist-object)
         (get-text-from-user "Enter gist id" "Enter gist id:")))
  (when (or gist-object gist-spec)
    (define gist
      (or gist-object
          (get-gist-object (gist-spec->id gist-spec))))
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
  (define dialog (new gist-dialog% [frame frame]))
  (send dialog add-gists gists)
  (send dialog show #t))

;; dialog% for displaying gists
(define gist-dialog%
  (class frame%
    (init-field frame)

    (define-values (display-w display-h)
      (get-display-size))

    (super-new [label "Public gists"]
               [width (/ display-w 2)]
               [height (/ display-h 2)])

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
           [frame frame]
           [parent panel]))))

;; for displaying a single gist in the list view
;; Note: only displays correctly in 5.3.2.2 and up
(define gist%
 (class group-box-panel%
   (init parent)
   (init-field gist-json frame)
   (super-new [label (string-append "gist id: "
                                    (dict-ref gist-json 'id))]
              [parent parent]
              [alignment '(left center)])

   (define gist-text (new text:hide-caret/selection%
                          [auto-wrap #t]))
   (define canvas (new editor-canvas%
                       [parent this]
                       [style '(no-border no-hscroll
                                no-vscroll transparent)]
                       [editor gist-text]))

   (define download-button
     (new button%
          [label "Open in DrRacket"]
          [parent this]
          [callback (λ (b e) (do-gist frame gist-json))]))

   (define description
     (let ([elem (dict-ref gist-json 'description)])
       (if (or (eq? 'null elem) (string=? "" elem))
           "No description provided"
           elem)))

   (define username
     (let ([user (dict-ref gist-json 'user)])
       (if (eq? user 'null)
           "anonymous"
           (dict-ref user 'login))))

   (define-values (l1 l2 l3 l4) ; save positions for later
     (values #f #f #f #f))

   (set-locs l1 l2 gist-text (send gist-text insert "url: "))

   (set-locs l3 l4 gist-text
    (do-url-clickback gist-text
     (send gist-text insert
           (dict-ref gist-json 'html_url))))

   (send gist-text insert "\n")

   (send gist-text change-style
         (make-object style-delta% 'change-bold)
         l1 l2)
   (send gist-text change-style
         (make-object style-delta% 'change-underline)
         l3 l4)

   (set-locs l1 l2 gist-text (send gist-text insert "user: "))
   (send gist-text insert username)
   (send gist-text change-style
         (make-object style-delta% 'change-bold)
         l1 l2)

   (send gist-text insert "\n")
   (send gist-text insert description)
   (send gist-text hide-caret #t)
   (send gist-text lock #t)

   ;; make sure canvas is as large as needed for text
   (define line-padding 2)
   (send canvas set-line-count
         (+ line-padding (send gist-text last-line)))))

;; Helpers
(define (url-callback text start end)
  (send-url (send text get-text start end)))

(define-syntax-rule (do-url-clickback text e ...)
  (do-clickback text url-callback e ...))

(define-syntax-rule (do-clickback text callback e ...)
  (let ([position (send text last-position)])
    e ...
    (send text set-clickback
          position (send text last-position) callback)))

(define-syntax-rule (set-locs x y text e ...)
  (begin
    (set! x (send text last-position))
    e ...
    (set! y (send text last-position))))

;; Tool setup
(define (phase1) (void))
(define (phase2) (void))

(drracket:get/extend:extend-unit-frame gist-frame-mixin)
