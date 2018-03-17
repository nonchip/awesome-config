gears = require "gears"
awful = require "awful"
awful.rules = require "awful.rules"
require "awful.autofocus"
wibox = require "wibox"
beautiful = require "beautiful"
naughty = require "naughty"
menubar = require "menubar"
mouseHandler = require "handler.mouse"
keyHandler = require "handler.key"
taglist = require "taglist"
lainLayout = require "lain.layout"
lain = require "lain"
ncclock = require "ncclock"

unpackJoin = (tablesTable) -> awful.util.table.join(unpack(tablesTable))
curdir = debug.getinfo(1, "S").source\sub(2)\match("(.*/)")

naughty.config.defaults.height = 24
naughty.config.defaults.width = 200

do
  in_error = false
  awesome.connect_signal "debug::error", (err)->
    return if in_error
    in_error = true
    naughty.notify {
      width: 600
      height: 60
      preset: naughty.config.presets.critical,
      title: "Oops, an error happened!",
      text:err
    }
    in_error = false

shell = (...)-> awful.spawn.with_shell(table.concat({...}," "))

shell_once = (...)->
  cmd=table.concat({...}," ")
  findme = cmd
  firstspace = cmd\find " "
  if firstspace
    findme = cmd\sub 1, firstspace
  awful.spawn.with_shell "pgrep -u $USER -x " .. findme .. " > /dev/null || pgrep -u $USER -fx " .. findme .. " > /dev/null || (" .. cmd .. ")"

shell 'xrandr --output HDMI-0 --preferred --primary'
shell 'xrandr --output DVI-I-0 --right-of HDMI-0'
--shell curdir..'/genentries'
--shell 'killall cinnamon-settings-daemon; sleep 1; cinnamon-settings-daemon'
--shell "killall compton; sleep 2; compton",
--  "-cCzG -t-3 -l-5 -r4",
--  "--config /dev/null",
--  "--backend glx --xrender-sync-fence --unredir-if-possible",
--  "--shadow-exclude 'argb && _NET_WM_OPAQUE_REGION@:c || bounding_shaped'"
--shell 'killall ckb; sleep 2; ckb --background'
--shell 'killall pulseaudio; sleep 2; start-pulseaudio-x11'
shell_once 'cinnamon-settings-daemon'
shell_once "compton",
  "-cCzG -t-6 -l-6 -r4 -i0.975",
  "--config /dev/null --blur-background --blur-kern 3x3gaussian",
  "--backend glx --xrender-sync-fence --unredir-if-possible",
  "--shadow-exclude 'argb && _NET_WM_OPAQUE_REGION@:c || bounding_shaped'",
  "--blur-background-exclude 'argb && _NET_WM_OPAQUE_REGION@:c || bounding_shaped'"
shell_once 'ckb --background'
shell 'pgrep -u $USER -x pulseaudio || start-pulseaudio-x11'
shell_once '/opt/Telegram/Telegram'
shell_once 'quasselclient'
shell_once 'claws-mail'
shell_once 'nm-applet'
shell_once "quodlibet"
shell_once "lutris"
shell "setxkbmap -option compose:rwin"
shell_once "/home/kyra/bin/Discord/Discord"

-- {{{ Variable definitions
beautiful.init(curdir.."themes/focuspoint/theme.lua")


beautiful.apw_show_text=true
APW = require "apw/widget"
APW.top = 3
APW.bottom = 3
APW.widget.forced_width = 30
APWTimer = timer timeout: 0.5
APWTimer\connect_signal "timeout", APW.Update
APWTimer\start!

modkey = "Mod4"

--with lainLayout.centerfair
--  .nmaster = 1
--  .ncol = 2

with awful.layout
  .layouts = {
    .suit.tile,
    .suit.spiral.dwindle,
    lainLayout.cascade,
    lainLayout.centerwork,
    lainLayout.termfair,
    .suit.max.fullscreen,
    .suit.floating
  }
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper
  for s = 1, screen.count!
    gears.wallpaper.maximized(beautiful.wallpaper, s, true)
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
--musicIcon = "6 <span font='FontAwesome 10'>  </span>"
--chatIcon = "7 <span font='FontAwesome 10'>  </span>"
--mytags = awful.tag({ 1, 2, 3, 4, 5, musicIcon, chatIcon }, s, awful.layout.layouts[1])
--for s = 1, screen.count!
--  -- Duplicate tags for each screen
--  tags[s] = mytags
tags = {
  [1]: awful.tag({ --left screen
    '1'
    '2'
    '3'
    '4'
  }, 1, awful.layout.layouts[1])
  [2]: awful.tag({ -- right screen
    '1'
    "2<span font='FontAwesome 9'></span>" -- that's a music note in fontawesome
  }, 2, awful.layout.layouts[1])
}
tags[2][1].master_width_factor=0.75
-- }}}

-- Menubar configuration
menubar.utils.terminal = 'st -e' -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
-- Create a textclock widget
--myclock = tzclock('', 2)
myclock = ncclock!
--nswclock = tzclock("AEST", 9) -- Doesn't account for daylight time

termquake=lain.util.quake{
  app: 'st'
  extra: '-e tmxgrp 0'
  argname: '-n %s'
  horiz: 'center'
  width: 0.9
  followtag: true
  height: 0.7
}


-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist =
  buttons: do
    :tag = awful
    mouseHandler
      left: tag.viewonly
      right: tag.viewtoggle
      scroll:
        up: (t)-> tag.viewnext(tag.getscreen(t))
        down: (t)-> tag.viewprev(tag.getscreen(t))
      meta:
        left: client.movetotag
        right: client.toggletag

clientsmenu = nil
mytasklist = {
  buttons: mouseHandler
    left: (c)->
      if c == client.focus
        c.minimized = true
      else
        c.minimized = false
        awful.tag.viewonly(c\tags![1])  if not c\isvisible!
        client.focus = c
        c\raise!
    right: ->
      if not clientsmenu
        clientsmenu = awful.menu.clients(theme: width: 250)
      else
        clientsmenu\hide!
        clientsmenu = nil
    scroll:
      up: ->
        awful.client.focus.byidx(1)
        client.focus\raise!  if client.focus
      down: ->
        awful.client.focus.byidx(-1)
        client.focus\raise!  if client.focus
}

for s = 1, screen.count!
  -- Create a promptbox for each screen
  mypromptbox[s] = awful.widget.prompt!
  -- Create an imagebox widget which will contains an icon indicating which layout we're using.
  -- We need one layoutbox per screen.
  mylayoutbox[s] = awful.widget.layoutbox(s)
  mylayoutbox[s]\buttons do
    :layouts, :inc = awful.layout
    mouseHandler
      left: -> inc(layouts, 1, 1)
      right: -> inc(layouts, -1, 1)
      scroll:
        up: -> inc(layouts, 1, 1)
        down: -> inc(layouts, -1, 1)
  -- Create a taglist widget
  mytaglist[s] = taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

  -- Create a tasklist widget
  mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

  -- Create the wibox
  mywibox[s] = awful.wibox(position: "top", screen: s)

  -- Widgets that are aligned to the left
  left_layout = wibox.layout.fixed.horizontal!
  left_layout\add(mytaglist[s])
  left_layout\add(mypromptbox[s])

  -- Widgets that are aligned to the right
  right_layout = wibox.layout.fixed.horizontal!
  right_layout\add(wibox.widget.systray!)
  right_layout\add(APW)
  right_layout\add(myclock)
--   right_layout\add(nswclock)
  right_layout\add(mylayoutbox[s])

  -- Now bring it all together (with the tasklist in the middle)
  layout = wibox.layout.align.horizontal!
  layout\set_left(left_layout)
  layout\set_middle(mytasklist[s])
  layout\set_right(right_layout)

  mywibox[s]\set_widget(layout)
-- }}}

-- {{{ Mouse bindings
  root.buttons mouseHandler
    swipeRight: awful.tag.viewnext
    swipeLeft: awful.tag.viewprev
-- }}}

focusByDirection = (dir) ->
  awful.client.focus.bydirection(dir)
  client.focus\raise!  if client.focus

-- {{{ Key bindings
globalkeys = do
  :tag, util:spawn:launch = awful
  keyHandler
    -- Display keys
    "XF86MonBrightnessUp": -> launch "xbacklight -inc 7", false
    "XF86MonBrightnessDown": -> launch "xbacklight -dec 7", false
    -- Volume keys
    "XF86AudioRaiseVolume": APW.Up
    "XF86AudioLowerVolume": APW.Down
    "XF86AudioMute": APW.ToggleMute
    -- Media keys
    "XF86AudioPrev": -> launch "quodlibet --previous"
    "XF86AudioStop": -> launch "quodlibet --pause"
    "XF86AudioPlay": -> launch "quodlibet --play-pause"
    "XF86AudioNext": -> launch "quodlibet --next"
    meta:
      -- Standard programs
      Tab: ->
        if awful.client.urgent and awful.client.urgent.get!
          awful.client.urgent.jumpto!
        else
          if n=awful.client.next(1)
            n\jump_to!
      --f: -> launch "nemo"
      e: -> launch "/opt/sublime_text_3/sublime_text"
      w: -> launch "chromium"
      r: -> --launch "xlunch --bc 00000077 -t -i "..os.getenv('HOME').."/.config/awesome/xlunch.cfg", false
        launch "rofi -combi-modi drun,run -scroll-method 1 -show-icons -modi combi -show combi"
      Return: termquake\toggle
      -- Jump between tags
      Left: tag.viewprev
      Right: tag.viewnext
      -- Layout manipulation
      j: -> focusByDirection("down")
      k: -> focusByDirection("up")
      h: -> focusByDirection("left")
      l: -> focusByDirection("right")
      u: awful.client.urgent.jumpto
      --"Tab": -> switcher(true)
      -- ";": -> switcher(false)
      -- Menubar
      p: -> menubar.show!

      shift:
        Tab: ->
          if n=awful.client.next(-1)
            n\jump_to!
        Return: ->
          launch 'st -e tmxgrp 0'
        j: -> awful.client.swap.byidx(1)
        k: -> awful.client.swap.byidx(-1)
        h: -> awful.tag.incnmaster(1)
        l: -> awful.tag.incnmaster(-1)
        space: -> awful.layout.inc(1, awful.screen.focused!.index)
        n: awful.client.restore

      ctrl:
        j: -> awful.tag.incmwfact(0.05)
        k: -> awful.tag.incmwfact(-0.05)
        h: -> awful.tag.incncol(1)
        l: -> awful.tag.incncol(-1)
        r: awesome.restart
        shift: q: awesome.quit


cleanup_temp_tags=->
  for s= 1, screen.count!
    for t in *awful.tag.gettags(s)
      tn=t.name
      if tn\match'〔[0-9]+〕' and #t\clients! < 1 and not t.selected
        t\delete!

get_or_create_tag=(screen,i)->
  gears.timer.delayed_call cleanup_temp_tags
  tag = awful.tag.gettags(screen)[i]
  return tag if tag
  awful.tag.add '〔'..i..'〕', {
    :screen
    layout: awful.layout.layouts[1]
    volatile: true
  }


clientkeys = do 
  gap_bak=beautiful.useless_gap
  keyHandler
    meta:
      f: (c)->
        c.fullscreen = not c.fullscreen
        --beautiful.useless_gap = c.fullscreen and 0 or gap_bak
      space:  awful.client.floating.toggle
      ctrl:
        "Return": (c)-> c\swap(awful.client.getmaster!)
      q: (c)->
        c\kill!
        gears.timer.delayed_call cleanup_temp_tags
      o: awful.client.movetoscreen
      t:(c)-> c.ontop = not c.ontop
      n:(c)-> c.minimized = true
      m: (c)->
        c.maximized_horizontal = not c.maximized_horizontal
        c.maximized_vertical = not c.maximized_vertical

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9
  globalkeys = awful.util.table.join globalkeys,
    keyHandler
      meta:
        -- View tag only
        ['#'..i+9]: ->
          tag = get_or_create_tag mouse.screen, i
          tag\view_only! if tag
          gears.timer.delayed_call cleanup_temp_tags
        -- Move client to tag
        shift: ['#'..i+9]: ->
          if client.focus
            tag = get_or_create_tag client.focus.screen, i
            awful.client.movetotag(tag)  if tag
          gears.timer.delayed_call cleanup_temp_tags
        -- Toggle tag
        ctrl:
          ['#'..i+9]: ->
            tag = get_or_create_tag mouse.screen, i
            awful.tag.viewtoggle(tag)  if tag
            gears.timer.delayed_call cleanup_temp_tags
          shift: ['#'..i+9]: ->
              if client.focus
                tag = get_or_create_tag client.focus.screen, i
                awful.client.toggletag(tag)  if tag
              gears.timer.delayed_call cleanup_temp_tags

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
clientbuttons = mouseHandler
  swipeRight: (c)-> awful.tag.viewnext(c.screen)
  swipeLeft: (c)-> awful.tag.viewprev(c.screen)
  left: (c)->
    client.focus = c
    c\raise!
  meta:
    left: awful.mouse.client.move
    right: awful.mouse.client.resize

awful.rules.rules = {
  {
--- defaults
    rule: {}
    except: 
      instance: "QuakeDD"
    properties:
      border_width: beautiful.border_width
      border_color: beautiful.border_normal
      focus: awful.client.focus.filter
      raise: true
      keys: clientkeys
      buttons: clientbuttons
    callback: (c)->
      c.maximized, c.maximized_vertical, c.maximized_horizontal = false, false, false
  }

--- left monitor
  {
    rule: class: "Chromium"
    properties: tag: tags[1][2]
  }
  {
    rule: class: "Claws-mail"
    properties: tag: tags[1][3]
  }
  {
    rule: name: "PlayOnLinux"
    properties: tag: tags[1][4]
    callback: (c)->
      if c.size_hints and c.size_hints.min_width==400 and c.size_hints.min_height==400 -- main window sets these
        return
      else
        c.floating = true
  }
  {
    rule: class: "Lutris"
    properties: tag: tags[1][4]
  }
  {
    rule: class: "Steam"
    properties: tag: tags[1][4]
  }
  {
    rule: class: "gw2-64.exe"
    properties: tag: tags[1][4], floating: true
  }
  {
    rule:
      class: "Steam"
      name: "^Steam %- News "
    callback: (c)->
      c\kill!
  }

--- right monitor
  {
    rule: class: "TelegramDesktop"
    properties:
      tag: tags[2][1]
    callback: awful.client.setslave
  }
  {
    rule: class: "discord"
    properties:
      tag: tags[2][1]
      floating: true
  }
  {
    rule: class: "Quasselclient"
    properties: tag: tags[2][1]
  }
  {
    rule: class: "Quodlibet"
    properties: tag: tags[2][2]
  }
}

-- Enable sloppy focus
client.connect_signal("mouse::enter", (c)->
  return  if awful.layout.get(c.screen) == awful.layout.suit.magnifier
  client.focus = c  if awful.client.focus.filter(c))

client.connect_signal("focus", (c)-> c.border_color = beautiful.border_focus)
client.connect_signal("unfocus", (c)-> c.border_color = beautiful.border_normal)
-- }}}
