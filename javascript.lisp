(in-package :static-web-js)

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

(defparameter *pixel-styles*
  '(top bottom left right width height border-width))

;; FIXME might be faster to setAttributes
(defpsmacro set-style ((&rest var) &rest args)
  `(setf
    ,@(loop for (a b) on args by #'cddr
            nconc
            `((@ ,@var style ,a)
                       ,(if (and b (member a *pixel-styles*)) `(+ ,b "px") b)))))

(defun this-swap (from to)
  (cond
    ((eql from 'this) to)
    (t
     (let ((sfrom (symbol-name from))
           (sto (symbol-name to)))
       (and (helpers:string-starts-with sfrom "THIS.")
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

(defparameter *js-file*
  (concatenate
   'string
   (let ((ps:*js-string-delimiter* #\'))
    (ps*
     '(progn

       (defvar *trace-level* 0)

       (defun get-by-id (id &optional (error t))
         (let ((hit ((@ document get-element-by-id) id)))
           (if hit
               (return hit)
               (if error (console "ERROR: get-by-id" id)))))

       (defun setup-packing (container-id item &optional (gutter 10))
         (let* ((container (get-by-id container-id))
                (pack (new (*packery container
                                     (create :item-selector (+ "." item)
                                             :gutter gutter)))))
           (setf (@ container pack) pack)))

       (defun select-page (index)
         (let ((pages (get-by-id "pages")))
           (setf (@ pages selected) index)))

       (defun show (id)
         (with-id (o id)
           (setf (@ o style visibility) "visible")))

       (defun hide (id)
         (with-id (o id)
           (setf (@ o style visibility) "hidden")))

       (defun when-ready (fn)
         ((@ document add-event-listener) "WebComponentsReady"
          (lambda () (funcall fn))))


       )))))

(defun js-file ()
  *js-file*)
