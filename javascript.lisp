(in-package :hackathon-js)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter *slash-representative-character* #\UE000))

(defpsmacro with-id ((var id) &body body)
  `(let ((,var (get-by-id ,id)))
     (if ,var
       (progn
         ,@body))))

(defpsmacro plusp (el)
  `(> ,el 0))

(defpsmacro console (&rest rest)
  `((@ console log) ,@rest))

(defpsmacro create-element (node-type)
  `((@ document create-element) ,node-type))

(defpsmacro set-inner-html (el html)
  `(setf (slot-value ,el 'inner-h-t-m-l) ,html))

(defpsmacro remove-node (el)
  `((@ ,el parent-node remove-child) ,el))

(defpsmacro ensure-loaded (name &body body)
  `(let ((fn (lambda () ,@body))
         (src (script-name-src ,name)))
     (if (script-loaded src)
         (funcall fn)
         (load-script src fn))))

(defparameter *pixel-styles*
  '(top bottom left right width height border-width))

;; FIXME might be faster to setAttributes
(defpsmacro set-style ((&rest var) &rest args)
  `(setf
    ,@(loop for (a b) on args by #'cddr
            nconc
            `((@ ,@var style ,a)
                       ,(if (and b (member a *pixel-styles*)) `(+ ,b "px") b)))))

(defun ensure-string (el)
  (if (null el) ""
    (typecase el
      (symbol (symbol-name el))
      (string el)
      (t (princ-to-string el)))))

(defun string-starts-with (string prefix &key (test #'char=))
  "Returns true if STRING starts with PREFIX."
  (let ((prefix (ensure-string prefix))
        (string (ensure-string string)))
    (let ((mismatch (mismatch prefix string :test test)))
      (or (not mismatch) (= mismatch (length prefix))))))

(defun this-swap (from to)
  (cond
    ((eql from 'this) to)
    (t
     (let ((sfrom (symbol-name from))
           (sto (symbol-name to)))
       (and (string-starts-with sfrom "THIS.")
            (intern (concatenate 'string sto "." (subseq sfrom 5))))))))

(defun subthis (this tree)
  (labels ((s (subtree)
             (or (and (symbolp subtree) (this-swap subtree this))
                 (cond ((atom subtree) subtree)
                       (t (let ((car (s (car subtree)))
                                (cdr (s (cdr subtree))))
                            (if (and (eq car (car subtree))
                                     (eq cdr (cdr subtree)))
                              subtree
                              (cons car cdr))))))))
    (s tree)))

(defpsmacro defun-trace (name args &rest body)
  (let* ((sname (ps::symbol-to-js-string name))
         (tname (ps-gensym name))
         (this (ps-gensym "this"))
         (arg-names (loop for arg in args
                          unless (eq arg '&optional)
                            collect (if (consp arg) (car arg) arg)))
         (argpairs
          (loop for arg in arg-names
                nconc (list (ps::symbol-to-js-string arg) arg))))
    `(progn
       (defun ,tname (,this ,@args)
         ,@(subthis this body))
       (defun ,name ,arg-names
         (console *trace-level* ,sname ":" ,@argpairs)
         (incf *trace-level*)
         (let ((rtn (,tname this ,@arg-names)))
           (decf *trace-level*)
           (console *trace-level* ,sname "returned" rtn)
           (return rtn))))))


(defun js-file ()
  *js-file*)
(defparameter *js-file*
  (concatenate
   'string
   (let ((ps:*js-string-delimiter* #\'))
     (ps*
      '(progn

        (defvar *trace-level* 0)

        (setf (@ *string prototype ends-with)
         (lambda (suffix) (return (not (== ((@ this index-of) suffix (- (@ this length) (@ suffix length))) -1)))))

        (defun get-by-id (id &optional (error t))
          (let ((hit ((@ document get-element-by-id) id)))
            (if hit
                (return hit)
                (if error (console "ERROR: get-by-id" id)))))

        (defun setup-packing (container-id item &optional (gutter 20))
          (let ((container (get-by-id container-id)))
            (if (@ container pack)
                ((@ container pack layout))
                (setf (@ container pack) (new (*packery container
                                                        (create :item-selector (+ "." item)
                                                                :gutter gutter)))))))

        (defun select-page (index)
          (cond
            ((= index 3) (setf (@ document title) "Missoula Civic Hackathon Schedule"))
            (t (setf (@ document title) "Missoula Civic Hackathon")))
          (let ((pages (get-by-id "pages")))
            (unless (=== (@ pages selected) index)
              (setf (@ pages selected) index)))
          (unless (= index 1)
            (unless *images-initialized* (setup-images))
            ((@ echo render))))

        (defun show (id)
          (with-id (o id)
            (setf (@ o style visibility) "visible")))

        (defun hide (id)
          (with-id (o id)
            (setf (@ o style visibility) "hidden")))

        (defun when-ready (fn)
          ((@ document add-event-listener) "WebComponentsReady"
           (lambda () (funcall fn))))

        (defun visit-url (url)
          ((@ window open) url "_blank"))

        (defun visit-email-list ()
          (visit-url "https://groups.google.com/forum/#!forum/missoula-civic-hackathon"))

        (defun join-school ()
          (visit-url "https://groups.google.com/forum/#!forum/missoula-civic-hackathon-students"))

        (defun visit-tickets ()
          (visit-url "https://www.eventbrite.com/e/missoula-civic-hackathon-2016-tickets-21898542129"))

        (defun visit-source-code ()
          (visit-url "https://github.com/Blue-Sky-Skunkworks/hackathon"))

        (defun setup-routing ()
          (page "/" (lambda () (select-page 1) (setup-packing "top-grid" "card")))
          (page "/press-release" (lambda () (select-page 2)))
          (page "/schedule" (lambda () (select-page 3)))
          (page "/sharing" (lambda () (select-page 4)))
          (page "/sponsors" (lambda () (select-page 5) (setup-packing "sponsors" "card" 60)))
          (page "/code-of-conduct" (lambda () (select-page 6)))
          (page "/participate" (lambda () (select-page 7)))
          (page "/prayer" (lambda () (select-page 8)))
          (page "/time" (lambda () (select-page 9)))
          (page "/government" (lambda () (select-page 10)))
          (page "/school" (lambda () (select-page 11)))
          (page "/media" (lambda () (select-page 12) (setup-packing "medias" "card" 60)))
          (page "/wiki/:page" (lambda (ctx) (ensure-loaded :marked (select-page 13) (setup-wiki (@ ctx params page)))))
          (page "/wiki" (lambda () (page "/wiki/Home")))
          (page (create :hashbang t)))


        (defun visit-url (url)
          ((@ window open) url "_blank"))

        (defun view-testers-message ()
          (visit-url "/includes/Senator-Tester-Spring-2016-Hackathon-Message.pdf"))

        (defun set-map-zoom (z)
          (let ((el (get-by-id "map")))
            (setf (@ el zoom) z
                  (@ el latitude) *vlat*
                  (@ el longitude) *vlon*)))

        (defun randomize-children (el)
          (loop
             for i from (@ el children length) downto 0
             do ((@ el append-child) (aref (@ el children) (ps:\| (* ((@ *math random)) i) 0)))))

        (defun animate-sponsors ()
          (set-timeout (lambda () (animate-sponsors-worker (get-by-id "sponsors"))) 10000))

        (defun animate-sponsors-worker (el)
          (randomize-children el)
          ((@ el pack fit) (aref (@ el children) 0) 0 0)
          (animate-sponsors))

        (defun stop-event (event)
          (when event
            (setf (@ event cancel-bubble) t
                  (@ event stopped) t)
            (when (@ event stop-propagation)
              ((@ event stop-propagation)))
            (if (= (@ navigator app-name) "Netscape")
                ((@ event prevent-default))
                (setf (@ (@ window event) return-value) nil)) ; IE
            ))

        (defvar *gallery*)

        (defun string-starts-with (string prefix)
          (return (== ((@ string index-of) prefix) 0)))

        (defun all-children (element)
          (return ((@ element get-elements-by-tag-name) "*")))

        (defun collect-children-with-prefix (root prefix)
          (let ((rtn (make-array)))
            (loop for el in (all-children root)
               do (when (string-starts-with (@ el id) prefix)
                    ((@ rtn push) el)))
            (return rtn)))

        (defun collect-container-images (container prefix current-id)
          (let* (index
                 (data
                  (loop for el in (collect-children-with-prefix container "i-")
                     for i from 0
                     collect
                       (let ((wh ((@ ((@ el get-attribute) "image-size") split) "x"))
                             (id (parse-int ((@ el get-attribute) "document-id")))
                             (caption  ((@ el get-attribute) "image-caption")))
                         (when (= current-id id) (setf index i))
                         (create :src (+ prefix id ".jpg")
                                 :node-id id :w (aref wh 0) :h (aref wh 1)
                                 :title caption)))))
            (return (list index data))))

        (defun show-image-gallery (event container-id prefix id)
          (stop-event event)
          (let* ((container (get-by-id container-id))
                 (images (collect-container-images container prefix id))
                 (gallery
                  (new (*photo-swipe (get-by-id "kspswp")
                                     *photo-swipe-u-i-_default
                                     ;; KLUDGE had to alter the js to rename the default variable
                                     ;; couldn't get parenscript to output the capital "D"
                                     (aref images 1)
                                     (create :index (aref images 0)))))))
          (setf *gallery* gallery)
          ((@ gallery init)))

        (defvar *logo-cell* nil)

        (defun arc (cx x y radius &key (start 0) (end (* (@ *math *p-i) 2)) fill line-width)
          ((@ cx begin-path))
          (when line-width (setf (@ cx line-width) line-width))
          ((@ cx arc) x y radius start end t)
          (if fill
              ((@ cx fill))
              ((@ cx stroke))))

        (defun animate-logo ()
          (let ((img ((@  document create-element) "img")))
            (setf *logo-cell* img
                  (@ img src) "/images/logo-cell.png")
            ((@ img add-event-listener) "load" animate-logo-go)))

        (defvar *life-size* 8)

        (defvar *life* (new (*uint8-array (* *life-size* *life-size*))))

        (defun life (row col) (return (aref *life* (+ (* row *life-size*) col))))

        (defun setup-life ()
          (loop for row from 0 to (- *life-size* 1)
             do (loop for col from 0 to (- *life-size* 1)
                   do (setf (aref *life* (+ (* row *life-size*) col))
                            (if (or (= col 0) (= row 0) (= row (- *life-size* 1)) (= col (- *life-size* 1))
                                    (and (= col 1) (= row 1))
                                    (and (= col 1) (= row (- *life-size* 2)))
                                    (and (= col (- *life-size* 2)) (= row (- *life-size* 2)))
                                    (and (= col (- *life-size* 2)) (= row 1)))
                                (if (< ((@ *math random)) 0.88) 1 0)
                                1)))))

        (defun animate-logo-go ()
          (let* ((canvas (get-by-id "logo"))
                 (cx ((@ canvas get-context) "2d")))
            (setup-life)
            ((@ cx clear-rect) 0 0 (@ canvas width) (@ canvas height))
            (loop
               for row from 0 to 7
               do
                 (loop for col from 0 to 7
                    do (when (life row col)
                         ((@ cx draw-image) *logo-cell* (+ 1 (* col 43)) (+ 2 (* row 42))))))

            (setf (@ cx fill-style) "white"
                  (@ cx stroke-style) "white")

            (arc cx 173 181 33 :fill t)
            (arc cx 173 181 111 :line-width 29)

            ((@ cx begin-path))
            (let ((theta (- (@ *math *p-i) (* (@ *math *p-i) (/ 69 180)))))
              ((@ cx arc) 173 181 111 theta (+ theta (- (/ (@ *math *p-i) 4.4))) t))
            ((@ cx line-to) 173 181)
            ((@ cx fill))

            ((@ cx save))
            ((@ cx begin-path))
            ((@ cx move-to) 173 164)
            ((@ cx line-to) 0 164)
            ((@ cx line-to) 0 0)
            ((@ cx line-to) 350 0)
            ((@ cx line-to) 350 340)
            ((@ cx line-to) 0 340)
            ((@ cx line-to) 0 198)
            ((@ cx line-to) 173 198)
            ((@ cx clip))

            (arc cx 173 181 62 :line-width 29)
            ((@ cx restore)))

          (set-timeout (lambda () (animate-logo-go)) 6000))

        (defvar *raw-wiki-url* "https://rawgit.com/wiki/Blue-Sky-Skunkworks/missoula-civic-hackathon-notes")
        (defvar *wiki-url* "https://github.com/Blue-Sky-Skunkworks/missoula-civic-hackathon-notes/wiki/")
        (defvar *wiki-page*)

        (defun request (url response-handler &optional (error-handler default-request-error-handler))
          (let* ((req (create-element "iron-request"))
                 (promise ((@ req send) (create :url url))))
            ((@ promise then) response-handler error-handler)))

        (defun default-request-error-handler (val)
          (console "error in request" val))

        (defun setup-wiki (page)
          (let ((title (get-by-id "wiki-title")))
            (request (+ (if *production* *raw-wiki-url* "/wiki") "/" page ".md") handle-wiki-response)
            (setf *wiki-page* page)
            (let ((text (+ "The Missoula Civic Hackathon Wiki — " ((@ page replace) (regex "/-/g") " "))))
              (setf (@ document title) text)
              (set-inner-html title text))))

        (defun handle-wiki-response (val)
          (let ((el (get-by-id "wiki-body")))
            (set-inner-html el (marked (@ val response)))))

        (defun get-inner-html (el)
          (return (slot-value el 'inner-h-t-m-l)))

        (defun select-ilink (ilink)
          (page (+ "/wiki/" ((@ ilink replace) (regex "/ /g") "-"))))

        (defun refresh-wiki ()
          (setup-wiki *wiki-page*))

        (defun view-wiki-source ()
          (visit-url (+ *wiki-url* *wiki-page*)))

        (defun edit-wiki ()
          (visit-url (+ *wiki-url* *wiki-page* "/_edit")))

        (defun toggle-wiki-view ()
          (let ((listing (get-by-id "wiki-listing"))
                (button (get-by-id "wiki-view-toggle")))
            (setf (@ button icon) (if (= (@ listing selected) 0) "toc" "list"))
            (setf (@ listing selected) (if (= (@ listing selected) 0) 1 0))))

        (defvar *images-initialized*)

        (defun setup-images ()
          (when *images-initialized* (console "Re-initializing images."))
          (setf *images-initialized* t)
          ((@ echo init)
           (create :offset 100
                   :throttle 250
                   :unload nil
                   :callback (lambda (el op) (console el op))))
          (dolist (panel '("sponsors-panel" "prayer-panel" "media-panel"))
            (watch-scrolling panel)))

        (defun watch-scrolling (id)
          (let ((el (get-by-id id)))
            ((@ el add-event-listener) "content-scroll" handle-scroll)))

        (defun handle-scroll ()
          ((@ echo render)))

        (defvar *scripts* (make-array))

        (defun script-name-src (name)
          (return (slot-value *script-name-src* name)))

        (defun script-loaded (src)
          (return (> ((@ *scripts* index-of) src) -1)))

        (defun load-script (src &optional callback)
          (if (script-loaded src)
              (console "duplicate script loading" src)
              (let* ((head (aref ((@ document get-elements-by-tag-name) "head") 0))
                     (css ((@ src ends-with) "css"))
                     (el ((@ document create-element) (if css "link" "script"))))
                (setf (@ el onload)
                      (lambda ()
                        (console "loaded" src)
                        (when callback (funcall callback)))
                      (@ el onerror) script-load-error)
                (cond
                  (css
                   (setf (@ el type) "text/css"
                         (@ el ref) "stylesheet"
                         (@ el href) src))
                  (t
                   (setf (@ el type) "text/javascript"
                         (@ el src) src)))
                ((@ head append-child) el))))

        (defun script-load-error (err)
          (throw (new (*u-r-i-error (+ "The script " (@ err target src) " is not accessible.")))))


        )))))
