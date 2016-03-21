(defsystem :hackathon
  :serial t
  :components ((:static-file "hackathon.asd")
               (:file "package")
               (:file "slime")
               (:file "config")
               (:file "utility")
               (:file "css")
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
               (:file "initialize"))
  :depends-on (:alexandria :cl-who :parenscript :hunchentoot :split-sequence))
