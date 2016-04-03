(in-package :hackathon)

(defun render-time (stream)
  (html
    (header-panel :mode "seamed"
                  (toolbar :class "time"
                           (:span :style "margin-left:0px;" :class "title" "The Time")
                           (icon-button :class "toolbar-icon" :style "margin-left:0px;" :icon "arrow-back" :onclick "page(\"/\");"))
                  (:div :style "padding:20px;background:black;" :class "fit layout vertical center-justified"
                        (:center
                         (:div :style "width:590px;height:590px;overflow:hidden;"
                               (:img :style "margin:-215px 0 0 -215px;" :width 1024 :height 1024
                                     :src "http://api.usno.navy.mil/imagery/moon.png")))))))

