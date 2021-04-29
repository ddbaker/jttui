#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# version 0.1.0

#
# Jakub Travnik's tui example
# This example does not use library of standard widgets (jttuistd.rb).
#
$: << File.dirname(__FILE__)

require "addlocalpath"
require "jttui/jttui"

class JTThww < JTTWindow
  def userinit
    super
    @lastkey = ""
  end

  def paintself(pc)
    super
    pc.fillrect 0, 0, w, h, ?\s.ord | JTTui.color_inactive_hi
    pc.windowframe self, JTTui.color_basic
    pc.move 2, 1
    pc.addstra "#{x} #{y} #{w} #{h}", JTTui.color_active_hi
    pc.move 2, 2
    pc.addstra "Hello World!", JTTui.color_active_hi
    pc.move 2, 3
    pc.addstr @lastkey if @lastkey
  end

  def mousepress(b, x, y)
    @lastkey = "mouse #{b} #{x},#{y}"
    JTTui.activewindow = self
    addmessage self, :paint
  end

  def keypress(key)
    @lastkey = key
    @lastkey = "key nr." + key[0].to_s if key[0].ord < 32
    addmessage self, :paint
    case key
    when "up"
      self.y = y - 1
    when "down"
      self.y = y + 1
    when "left"
      self.x = x - 1
    when "right"
      self.x = x + 1
    when "home"
      self.w = w - 1 if w > 0
    when "end"
      self.w = w + 1
    when "pgup"
      self.h = h - 1 if h > 0
    when "pgdn"
      self.h = h + 1
    when "1".."6"
      self.align = key.to_i - 1
    when "a"
      JTTui.activewindow = JTTui.findwindowbyname "Hello Window1"
    when "b"
      JTTui.activewindow = JTTui.findwindowbyname "Hello Window2"
    when "c"
      JTTui.activewindow = JTTui.findwindowbyname "Hello Window3"
    when "q"
      addmessage nil, :quitloop, key
    else
      addmessage @parent, :keypress, key
    end
  end
end

puts "This is demo of jttui, but without using standard widgets from jttuistd"
puts "Keys: q         -exit (you can exit with C-c too)"
puts "                 note: you can use ESC-digit to simulate F1-F10"
puts "      arrows    -move with active window"
puts "      pgdn/pgup -change width of window"
puts "      home/end  -change height of window"
puts "      mouse     -click on window to make it active"
puts "                 mouse should work on linux console (using gpm) or xterm"
puts "      a,b,c     -activate one of three moveable windows"
puts "Press enter to start (you will be prompted to describe key on first run)"
gets

JTTui.run do |root|
  cw = JTTWindow.new(root, "Container Window", 7, 8, 60, 15)
  def cw.paintself(pc)
    super
    pc.fillrect 0, 0, w, h, ?\s.ord | JTTui.color_active_hi
    pc.windowframe self, JTTui.color_basic
    pc.move 1, 1
    pc.addstra "#{x} #{y} #{w} #{h}", JTTui.color_active
  end
  cw2 = JTTWindow.new(cw, "Container Window2", 2, 2, 40, 10)
  def cw2.paintself(pc)
    super
    pc.fillrect 0, 0, w, h, ?\s.ord | JTTui.color_active_hi
    pc.windowframe self, JTTui.color_basic
    pc.move 1, 1
    pc.addstra "#{x} #{y} #{w} #{h}", JTTui.color_active
  end
  hww1 = JTThww.new(cw2, "Hello Window1", 1, 1, 15, 5)
  hww2 = JTThww.new(cw2, "Hello Window2", 15, 1, 15, 5)
  hww3 = JTThww.new(root, "Hello Window3", 15, 1, 15, 5)
end
