# -*- coding: utf-8 -*-
#
# this is contribution from Steven Grady
# it is vertical messagebox widget
#

class VMessagebox < JTTWMessagebox
  def execute(thetext=@text)
    @result=-1
    mesdlg=JTTDialog.new(JTTui.rootwindow, 'Messagebox Window '+id.to_s,
                         0,0,0,0,'')
    mesdlg.align=JTTWindow::ALIGN_CENTER
    mesdlg.up
    wsize=1 # compute width of array of buttons
    realbuttons=[]
    @buttons.each_with_index { |bname,index|
bwsize=JTWHilightletter.hl_countchars(bname) + 4
      realbuttons << JTTWButton.new(mesdlg, 'Messagebox Button',
                                    0,0,bwsize,1,bname) {
        @result=index
        mesdlg.addmessage nil, :quitloop
      }
      wsize = [wsize, bwsize].max
    }
    wsize+=2
    wsize=[wsize,@minwidth].max
    label=JTTWLabel.new(mesdlg, 'Messagebox Label '+id.to_s,
                        1, 1, wsize-4, 1, thetext)
    hlsize=[label.breaklines.length, mesdlg.parent.h-5].min
    label.h=hlsize
    hsize=hlsize+5+@buttons.length
realbuttons.each_with_index{|b,i| b.y=hsize-5+i}
    mesdlg.h=hsize
    mesdlg.w=wsize
    mesdlg.addmessage mesdlg, :paint
    realbuttons.each{|b| mesdlg.addtabstop b}
    if @cancelnr==-1
      def mesdlg.keypress(k)
        if k=='esc'
          JTTui.addmessage nil, :quitloop
        else
          super
        end
      end
    elsif @cancelnr # if not nil
      mesdlg.cancelbutton=realbuttons[@cancelnr]      
    end
    mesdlg.settab realbuttons[@defaultnr]
    JTTui.messageloop
    mesdlg.close
    @result
  end
end

