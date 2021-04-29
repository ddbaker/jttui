#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# version 0.1.0

#
# Jakub Travnik's tui example
# this example uses widgets from jttuistd.rb
#
$: << File.dirname(__FILE__)

require 'addlocalpath'
require 'jttui/jttui'
require 'jttui/jttuistd'


JTTui.run do |root|
  d1=JTTDialog.new(root, 'Dialog Window', 0, 0, 60, 16, 'Example 3')
  d1.align=JTTWindow::ALIGN_CENTER
  la2=JTTWLabel.new(d1, 'Test Label', 15, 1, 40, 1, 'Scrollbox1 not used yet.')
  sc1=JTTWScrollbox.new(d1, 'Scroll box1', 2, 0, 12, 7, 22, 13) {
    if @scrolltimes
      @scrolltimes+=1
    else
      @scrolltimes=1
    end
    la2.caption="You have used scrollbox1 #{@scrolltimes} times."}
  sc2=JTTWScrollbox.new(d1, 'Scroll box2', 2, 7, 12, 7, 22, 11)
  la1=JTTWLabel.new(sc1, 'Test Label', 1, 1, 20, 11,
		    'Use arrow keys or home, end, pgup, pgdn, C-e, C-a, '+
		    'C-f, C-b, C-n, C-p, M-b, M-f, M-v, C-v, M->, M-< to '+
		    'scroll this window. If contained windows use this keys '+
		    'too, their scroll function will not apply.')
  la1.color=JTTui.color_edit
  la1.color_hi=JTTui.color_edit_hi

  la3=JTTWLabel.new(d1, 'Test Label', 15, 3, 40, 1, 'Value not changed.')
  scb1=JTTWScrollbar.new(d1, 'Scroll bar', 15, 4, 40, 1, true) {
    la3.caption="Value is %2.1f%%." % (scb1.scroller.normalizedposition)
  }
  scb1.scroller.setsteps(100,10,100)
  # 100 small steps per bar, 10 pages per bar, 100 scale

  ll1=JTTWListLabels.new(d1, 'List labels1', 16, 6, 8, 8)
  ll1.list=(0...100).collect{ |i| "line no. #{i}"+("\n"*(i % 3)) }
  ll1.update

  lb1=JTTWListButtons.new(d1, 'List buttons1', 26, 6, 13, 8) { |who,idx|
    JTTWMessagebox.new("You have pressed button nuber #{idx}",
		       0,0,'_Ok').execute
  }
  lb1.list=(0...1000).collect{ |i| "Button #{i}" }
  lb1.update

  lc1=JTTWListCheckboxes.new(d1, 'List checkbox1', 41, 6, 16, 6)
  lc1.list=(0...100).collect{ |i| "Checkbox #{i}" }
  lc1.states=(0...100).collect{ |i| i % 2 }
  lc1.update

  sc2buttons=[]
  %w{one two tree four five six seven eight nine ten}.each{ |bname|
    sc2buttons << JTTWButton.new(sc2, 'Button:'+bname,
				 1, sc2buttons.length, 9, 1, bname) { |button|
          JTTWMessagebox.new('You have pressed button '+
			     button.caption,0,0,'_Ok').execute
    }
  }

  wbquit=JTTWButton.new(d1, 'Test Button', 48, 13, 8, 1, '_Quit') {
    JTTui.addmessage nil, :close}
  d1.addtabstop sc1
  d1.addtabstop scb1
  sc2buttons.each{|b| d1.addtabstop b}
  d1.addtabstop ll1
  d1.addtabstop lb1
  d1.addtabstop lc1
  d1.addtabstop wbquit
  d1.cancelbutton=wbquit
end
