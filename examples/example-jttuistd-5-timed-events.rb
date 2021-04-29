#!/usr/bin/env ruby

# version 0.1.0

#
# Jakub Travnik's tui example
# this example uses widgets from jttuistd.rb
#

require 'addlocalpath'
require 'jttui/jttui'
require 'jttui/jttuistd'

JTTui.run do |root|
  d1=JTTDialog.new(root, 'Dialog Window', 0, 0, 60, 16,
		   'Example 5 - timed events')
  d1.align=JTTWindow::ALIGN_CENTER
  
  la=[];bstop=[];bstart=[];counter=[];nextaction=[]
  [[0,0,1],[0,5,2],[0,10,3],[25,0,4],[25,5,5]].each_with_index{
    |timergroup,tgid|
    relx,rely,speed=*timergroup
    la << JTTWLabel.new(d1, 'Test Label', 3+relx, 1+rely,12,1,'Press start.')
    counter << 0
    nextaction << nil
    bstart << JTTWButton.new(d1, 'Test Button', 1+relx, 3+rely,8,1,'Start') {
      unless nextaction[tgid]
	nextaction[tgid]=Proc.new {
	  la[tgid].caption=counter[tgid].to_s
	  counter[tgid]+=1
	  JTTui.after(speed, &nextaction[tgid]) if nextaction[tgid]
	}
	nextaction[tgid].call
      end
    }
    bstop << JTTWButton.new(d1, 'Test Button', 13+relx, 3+rely,8,1, 'Stop') {
      nextaction[tgid]=nil
    }
  }

  wbquit=JTTWButton.new(d1, 'Test Button', 48, 13, 8, 1, '_Quit') {
    JTTui.addmessage nil, :close}
  bstart.length.times { |i|
    d1.addtabstop bstart[i]
    d1.addtabstop bstop[i]
  }
  d1.addtabstop wbquit
  d1.cancelbutton=wbquit
end
