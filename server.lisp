(in-package :hackathon)

(defvar *web-acceptor* nil)

(defclass web-acceptor (hunchentoot:acceptor)
  ((dispatch-table :reader dispatch-table :initarg :dispatch-table)))

(defun create-exact-dispatcher (name handler)
  "Creates a request dispatch function which will dispatch to the
function denoted by HANDLER if the file name of the current request
matches NAME."
  (lambda (request)
    (and (equal name (script-name request))
         handler)))

(defun format-dispatch (dispatch)
  (if (consp dispatch)
      (ecase (first dispatch)
        (:prefix (hunchentoot:create-prefix-dispatcher (second dispatch) (third dispatch)))
        (:exact (create-exact-dispatcher (second dispatch) (third dispatch)))
        (:regex (hunchentoot:create-regex-dispatcher (second dispatch) (third dispatch)))
        (:folder (hunchentoot:create-folder-dispatcher-and-handler (second dispatch) (third dispatch)))
        (:static (hunchentoot:create-static-file-dispatcher-and-handler (second dispatch) (third dispatch))))
      dispatch))

(defun start-server ()
  (when *web-acceptor*
    (warn "Server already started. Restarting")
    (hunchentoot:stop *web-acceptor*))
  (setf *web-acceptor*
        (make-instance 'web-acceptor
                       :port 3000
                       :access-log-destination (hackathon-file (format nil "log/access-~A.log" (now)))
                       :message-log-destination (hackathon-file (format nil "log/message-~A.log" (now)))
                       :dispatch-table (mapcar 'format-dispatch
                                               `((:prefix "/t/" handle-tracker-request)
                                                 (:folder "/wiki/" ,(hackathon-file "missoula-civic-hackathon-notes.wiki/"))
                                                 (:folder "/includes/" ,(hackathon-file "includes/"))
                                                 (:folder "/modules/" ,(hackathon-file "modules/"))
                                                 (:folder "/fonts/" ,(hackathon-file "fonts/"))
                                                 (:exact "/" render-front-page)
                                                 (:folder "/" ,(hackathon-file "build/"))))))
  (hunchentoot:start *web-acceptor*))

(defmethod hunchentoot:acceptor-dispatch-request ((acceptor web-acceptor) request)
  (iter (for dispatcher in (dispatch-table acceptor))
        (when-let (action (funcall dispatcher request))
          (return (funcall action)))
        (finally (call-next-method))))

