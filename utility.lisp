(in-package :hackathon)

(enable-sharpl-reader)

(defmacro html (&body body) `(with-html-output (stream nil) ,@body))
(defmacro html-to-string (&body body) `(with-html-output-to-string (stream nil) ,@body))

(defun asdf-base-path (name)
  (directory-namestring (asdf:component-pathname (asdf:find-system name))))

(defun hackathon-file (&optional base)
  (concatenate 'string (asdf-base-path :hackathon) base))

(defmacro vertical-break (&optional (height "20px"))
  `(html (:div :style ,(format nil "height:~A;" height))))

(defvar *note-lock* (sb-thread:make-mutex))
(defparameter *inhibit-note* nil)

(defmacro with-note-lock (&body body) `(with-mutex (*note-lock*) ,@body))

(defparameter *note-start-clock* (let ((now (get-universal-time)))
                                   (format t "~&;;  Note logging started at: ~A.~%" now)
                                   now))

(defun note (control &rest arguments)
  (unless *inhibit-note*
    (let ((*print-pretty* nil))
      (sb-thread:with-mutex (*note-lock*)
        (apply #'format t (format nil "~~&;; ~A ~A~~%" (princ-to-string (- (get-universal-time) *note-start-clock*)) control) arguments)
        (finish-output t)))))

(defun ensure-trailing-slash (string &optional (slash-character #\/))
  (if (char= (aref string (1- (length string))) slash-character)
    string
    (with-output-to-string (stream)
      (write-string string stream)
      (write-char slash-character stream))))

(defun run-program-to-string (program args)
  (with-output-to-string (str)
    (sb-ext:run-program program args :output str :error str :search t)))

(defun png-image-size (filename)
  (unless (probe-file filename) (error "Missing ~S." filename))
  (values-list (mapcar #'parse-integer (split-sequence #\x (third (split-sequence #\space (run-program-to-string "identify" (list filename))))))))

(defun slurp-file (filename &optional external-format)
  (with-input-from-file (stream filename :external-format (or external-format :utf-8))
    (let* ((len (file-length stream))
           (seq (make-string len))
           (actual-len (read-sequence seq stream)))
      (if (< actual-len len)
        ;; KLUDGE eh, FILE-LENGTH doesn't know about utf8 so we use some duct tape
        (string-right-trim '(#\nul) seq)
        seq))))

(defmacro to-json (item)
  `(json:encode-json-to-string ,item))

(defmacro from-json (item)
  `(json:decode-json-from-string ,item))

(defun mkstr (&rest args)
  (with-output-to-string (s)
    (dolist (a args) (when a (princ a s)))))

(defun symb (&rest args)
  (values (intern (apply #'mkstr args))))

(defun ksymb (&rest args)
  (values (intern (apply #'mkstr args) :keyword)))

(defmacro with-assoc-values ((alist names &key (test 'eql)) &body body)
  (with-gensyms (data)
    `(let* ((,data ,alist)
            ,@(iter (for name in (ensure-list names))
                    (collect `(,(symb (string-upcase name)) (assoc-value ,data ,name :test ',test)))))
       ,@body)))
