(defsystem :hackathon
  :serial t
  :depends-on ("alexandria" "cl-who" "parenscript" "hunchentoot" "split-sequence" "zpng" "cl-json" "cl-ppcre")
  :components ((:static-file "hackathon.asd")
               (:file "package")
               (:file "slime")
               (:file "config")
               (:file "utility")
               (:file "css")
               (:file "tracker")
               (:file "server")
               (:file "polymer")
               (:file "javascript")
               (:file "build")
               (:file "analytics")
               (:file "front-page")
               (:file "press-release")
               (:file "schedule")
               (:file "sharing")
               (:file "sponsors")
               (:file "code-of-conduct")
               (:file "participate")
               (:file "prayer")
               (:file "moon")
               (:file "initialize")))
