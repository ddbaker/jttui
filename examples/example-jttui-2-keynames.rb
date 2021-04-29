#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# version 0.1.0

#
# Jakub Travnik's tui example
# This example does not use library of standard widgets (jttuistd.rb).
#

require 'addlocalpath'
require 'jttui/jttui'

puts 'This is demo of jttui without standard widgets.'
puts 'Every pressed key is printed.'
puts 'Note: JTTui does not print characters with codes bellow 32, you will see ? instead'
puts 'PRESS q KEY TO QUIT!'
puts 'Press enter to start (you will be prompted to describe key on first run)'
exit if gets.chomp=='q'

JTTui.run do |root|
  w=JTTWindow.new(root, 'Keynames Window', 7, 8, 60, 15)
  def w.initmore
    @lastarr=[];@lastkey=nil
  end
  w.initmore
  def w.paintself(pc)
    super
    pc.fillrect 0, 0, w, h, ?\s|JTTui.color_active_hi
    pc.windowframe self, JTTui.color_basic
    pc.move 3,0
    pc.addstra 'PRESS q KEY TO QUIT',JTTui.color_active_hi
    pc.move 1,1
    pc.addstra "Name of last pressed key is: #{@lastkey}",
      JTTui.color_inactive_hi
    pc.move 1,2
    pc.addstra "Key string is: #{@lastkey.inspect}", JTTui.color_inactive_hi
    pc.move 1,4
    pc.addstr "Array of keys pressed so far:"
    pc.move 2,5
    str=@lastarr.inspect
    ws=self.w-4
    lines=1
    while str.length>ws
      pc.addstr str[0...ws]
      pc.moverel -ws,1
      str=str[ws..-1]
      lines+=1
    end
    pc.addstr str
    # truncate array to fit to window if necessary
    @lastarr=[@lastarr.last] if lines > self.h-7
  end
  def w.mousepress(b,x,y)
    @lastkey="mouse #{b} #{x},#{y}"
    @lastarr << @lastkey
    addmessage self, :paint
  end
  def w.keypress(key)
    @lastkey=key
    @lastarr << @lastkey
    addmessage self, :paint
    addmessage @parent, :close if key=='q'
  end
  JTCur.raw
end
