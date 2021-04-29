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
		   'Example 1 - simple dialog')
  d1.align=JTTWindow::ALIGN_CENTER
  wb1=JTTWButton.new(d1, 'Test Button', 3, 2, 11, 1, 'Button_1') {
    JTTui.beep}
  wb2=JTTWButton.new(d1, 'Test Button', 3, 3, 11, 1, 'Button_2') {
    JTTui.beep;sleep 1; JTTui.beep}
  wb3=JTTWButton.new(d1, 'Test Button', 3, 4, 11, 1, 'Button_3') {
    JTTui.beep;sleep 1; JTTui.beep;sleep 1; JTTui.beep}
  wbquit=JTTWButton.new(d1, 'Test Button', 48, 13, 8, 1, '_Quit') {
    JTTui.addmessage nil, :close}
  el1=JTTWEditline.new(d1, 'Test Editline1', 3, 11, 20, 1,
		       'Hello this is edit-line', true)
  el2=JTTWEditline.new(d1, 'Test Editline2', 3, 13, 20, 1,
		       'This one is read-only', false)
  la1=JTTWLabel.new(d1, 'Test Label', 3, 6, 23, 5,
		    'Test _Label with text wrapping can'+
                    ' select the widget bellow. '+
		    'This edit line widget uses emacs like keys.'){
    d1.settab el1}
  ch1=JTTWCheckbox.new(d1, 'Test Checkbox', 20, 2, 13, 1, '_Checkbox1')
  ch2=JTTWCheckbox.new(d1, 'Test Checkbox', 20, 3, 13, 1, 'C_heckbox2') {
  JTTui.beep }
  ch2.states=3
  rg1=JTTWRadiogroup.new(d1, 'Test Radiogroup', 30, 5, 8, 2,
			 ['O_ne','T_wo'],-1)
  rg2=JTTWRadiogroup.new(d1, 'Test Radiogroup', 40, 5, 13, 4,
			 ['_One','_Two','Th_ree','_Four'],2) { JTTui.beep }
  wb4=JTTWButton.new(d1, 'Test Button', 30, 11, 17, 1, 'Test _Messagebox') {
    
    m1=JTTWMessagebox.new("Choose character for background\n"+
			  "note: shapes are terminal dependent", 0, 3,
			  "_1: \1","_2: \4","_3: \7","_4: \0",
			  "_5: \11","_6: none")
    m2=JTTWMessagebox.new('',0,0,'_I\'m happy','_Try again')
    begin
      res=m1.execute
      if res>=0
	char="\1\4\7\0\11 "[res]
	char=char | (res==5 ? JTTui.color_background : JTTui.color_basic)
	JTTui.rootwindow.background=char
      end
      m1.defaultnr=res # remember previous choose
    end until 0==m2.execute("You have pressed no. #{res}")
    JTTWMessagebox.new('Thank you for trying message box widget behaviour. '+
		       'Notice that long messages should be in bigger window.',
		       0, 0, '_Ok').execute
  }
  d1.addtabstop wb1
  d1.addtabstop wb2
  d1.addtabstop wb3
  d1.addtabstop ch1
  d1.addtabstop ch2
  d1.addtabstop rg1
  d1.addtabstop rg2
  d1.addtabstop el1
  d1.addtabstop el2
  d1.addtabstop wb4
  d1.addtabstop wbquit
  la1.down
  d1.cancelbutton=wbquit
  d1.defaultbutton=wb1
end
