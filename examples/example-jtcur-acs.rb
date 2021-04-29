#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# version 0.1.0

# Example of jtcur curses interface
# this will display acs characters
#
# note: some or all may not appear correctly on some terminals

require 'addlocalpath'
require 'jtcur'

include JTCur

init_screen
start_color
cbreak
noecho
nonl

y=0
JTCur.methods.grep(/acs_/) do |m|
  move((y % 3)*20,y/3)
  y+=1
  addstr "#{m}: "
  addch JTCur.send m
  addstr ""
end
move 0,13
addstr "+ì¹èø¾ýáíé"
"+ì¹èø¾ýáíé".each_byte{|x| addch x}

(0..31).each{ |i|
  move(0,15+i/8) if i%8==0
  addstr( ("\\%02o=" % i)+(i.chr)+'  ')
}
move 0,20
addstr "\0\1\2\3\4\5\6\7\10\11\12\13\14\15\16\17"+
 "\20\21\22\23\24\25\26\27\30\31\32\33\34\35\36\37"
move 0,22
addstr "press any key to exit"
refresh
STDIN.getc

echo
nocbreak

close_screen

