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
  d1=JTTDialog.new(root, 'Dialog Window', 0, 0, 75, 23,
		   'Example 6 - Ascii table')
  d1.align=JTTWindow::ALIGN_CENTER
  l1=JTTWLabel.new(d1, 'Label 1', 0,0,40,1,'Char Hex Oct Dec, Use ^c to exit')
  ll1=JTTWListLabels.new(d1, 'List labels1', 1, 1, 20, 20)
  ll1.list=(0...256).collect{ |i| "%s   %2x  %3o %3i"  %
      [((i&0x7f) < 32) ? " " : i.chr,i,i,i]}
  ll1.update
  
end
