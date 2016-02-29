(in-package :static-web)

(defun render-front-page ()
  (html-to-string
    (:html
      (:head
       (:title "Static Web")

       (:script :src "/js/webcomponentsjs/webcomponents-lite.js" :type "text/javascript")
       (:link :rel "import" :href "/js/polymer/polymer.html")
       (:link :rel "stylesheet" :type "text/css" :href "/css.css")

       (iter (for name in '("polymer"
                            "iron-flex-layout"
                            "iron-icons"
                            "paper-styles"
                            "paper-header-panel"
                            "paper-toolbar"
                            "paper-icon-button"
                            "paper-scroll-header-panel"
                            "paper-button"
                            "paper-dialog"
                            "paper-input"
                            "neon-animation"))
             (htm (:link :rel "import" :href (format nil  "/js/~A/~A.html" name name))))

       (:script :src "/js/js.js" :type "text/javascript"))

      (:body :class "fullbleed layout vertical"
             (header-panel :mode "seamed"
                           (toolbar (:title ("basebox"))
                             (icon-button :icon "exit-to-app" :style "margin-right:0px;" :onclick "showDialog(\"i-sign-in\");"))
                           (:div :class "image" (:center (:img :src "/images/mockup-001.png"))))
             (p-dialog "i-sign-in" (:entry "fade-in-animation" :exit "fade-out-animation")
               (:h1 "Sign in")
               (input :id "i-username" :label "Username" :autofocus t)
               (input :id "i-password" :type "password" :label "Password")
               (:div :class "buttons"
                     (button "closeDialog(\"i-sign-in\");" "CANCEL")
                     (button "signIn();" "ACCEPT")))))))

(defun build-webpage-directory (path fn)
  )

(defun build-webpage-generated (path fn)
  (ensure-directories-exist path)
  (with-output-to-file (stream path :if-exists :overwrite :if-does-not-exist :create)
    (let ((body (funcall fn)))
      (when body (write-string (funcall fn) stream)))))

(defun build-webpage (path fn)
  (if (uiop:directory-pathname-p path)
      (build-webpage-directory path fn)
      (build-webpage-generated path fn)))

(defun build-website (description)
  (iter (for (path fn) in description)
        (build-webpage
         (static-web-file
          (concatenate 'string
                       "build/"
                       (if (char= (char path 0) #\/)
                           (subseq path 1)
                           path)))
         fn)))

(defun build ()
  (build-website '(("/js/js.js" build-javascript)
                   ("/js/" populate-javascript)
                   ("/css/css.css" build-stylesheet)
                   ("/index.html" render-front-page))))

(defun build-javascript ())
(defun build-stylesheet ())
