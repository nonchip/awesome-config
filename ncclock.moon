wibox = require "wibox"

return ->
  w = wibox.widget.textbox!
  t = timer timeout: 1
  t\connect_signal 'timeout', ->
    w\set_markup(os.date("<span font='square 7'>%a %Y-%m-%d</span> <span font='square 9'>%H%M</span>"))
  t\start!
  t\emit_signal 'timeout'
  return w
