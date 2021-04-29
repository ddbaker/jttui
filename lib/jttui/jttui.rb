# -*- coding: utf-8 -*-
#
# Jakub Travnik's textmode user interface
# classes for dealing with basics of text user interface
#
# This file is distributed under this license:
# Jakub Travnik's textmode user interface (JTTui) is copyrighted free software
# by Jakub Travnik <J.Travnik@sh.cvut.cz> or <jakub.travnik@rocketmail.com>.
# You can redistribute it and/or modify it under either the terms of the GPL
# (see COPYING.GPL file), or the conditions below:
#
#    1. You may make and give away verbatim copies of the source form of
#       the software without restriction, provided that you duplicate all of
#       the original copyright notices and associated disclaimers.
#
#    2. You may modify your copy of the software in any way, provided
#       that you do at least ONE of the following:
#
#         a) place your modifications in the Public Domain or otherwise
#         make them Freely Available, such as by posting said modifications to
#         Usenet or an equivalent medium, or by allowing the author to include
#         your modifications in the software.
#
#         b) use the modified software only within your corporation or
#         organization.
#
#         c) rename any non-standard executables so the names do not
#         conflict with standard executables, which must also be provided.
#
#         d) make other distribution arrangements with the author.
#
#    3. You may distribute the software in object code or executable
#       form, provided that you do at least ONE of the following:
#
#         a) distribute the executables and library files of the
#            software, together with instructions (in the manual page or
#            equivalent) on where to get the original distribution.
#
#         b) accompany the distribution with the machine-readable source
#            of the software.
#
#         c) give non-standard executables non-standard names, with
#            instructions on where to get the original software distribution.
#
#         d) make other distribution arrangements with the author.
#
#    4. You may modify and include the part of the software into any other
#       software (possibly commercial).  But some files in the distribution
#       are not written by the author, so that they are not under this terms.
#
#       They are currently none. You may find them in ./contrib directory
#       of source tree. See each file for the copying condition.
#
#    5. The scripts and library files supplied as input to or produced
#       as output from the software do not automatically fall under the
#       copyright of the software, but belong to whomever generated them, and
#       may be sold commercially, and may be aggregated with this software.
#
#    6. THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#       IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
# end of license

require 'jtcur'
require 'observer'

require 'jttui/jtkey'
require 'jttui/jtutil'


def jttui_version
  '0.11.0/2002-05-08 20:55 CEST'
end

# common window excepton class
class JTTWindowException < RuntimeError
end

class JTRectangle
  include Observable
  attr_reader :x, :y, :w, :h
  def initialize(x,y,w,h) # x+w-1 (y+h-1) is most left (bottom) element
    @x=x; @y=y; @w=w; @h=h
  end
  def dup; JTRectangle.new(@x, @y, @w, @h) end
  def ex; @x+@w end
  def ey; @y+@h end
  def x=(v); @x=v; changed; notify_observers self end
  def y=(v); @y=v; changed; notify_observers self end
  def w=(v)
    if v<0
      raise RuntimeError ,"invalid rectangle (in w=)", caller
    end
    @w=v; changed; notify_observers self
  end
  def h=(v)
    if v<0
      raise RuntimeError ,"invalid rectangle (in h=)", caller
    end
    @h=v; changed; notify_observers self
  end
  def ex=(v)
    @w=v-@x
    if @w<0
      raise RuntimeError ,"invalid rectangle (in w=)", caller
    end
    changed; notify_observers self
  end
  def ey=(v)
    @h=v-@y
    if @h<0
      raise RuntimeError ,"invalid rectangle (in h=)", caller
    end
    changed; notify_observers self
  end
  def xrange; @x ... @x+@w end
  def yrange; @y ... @y+@h end
  def set(x, y, w, h)
    if w<0 or h<0
      raise RuntimeError ,"invalid rectangle (set)", caller
    end
    @x=x; @y=y; @w=w; @h=h
    changed; notify_observers self
  end
  def crop(other)
    newcoords=JTCur.crop @x, other.x, @y, other.y, @w, other.w, @h, other.h
    JTRectangle.new(*newcoords) if newcoords
  end
  def enlarge(other)
    newcoords=(x < other.x ? x : other.x),
      (y < other.y ? y : other.y),
      (ex > other.ex ? ex : other.ex),
      (ey > other.ey ? ey : other.ey)
    JTRectangle.newabs(*newcoords) if newcoords
  end
  def include? (x,y)
    @x<=x and x<(@x+@w) and @y<=y and y<(@y+@h)
  end
  def ==(other)
    @x==other.x and @y==other.y and @w==other.w and @h==other.h
  end
end
def JTRectangle.newabs(sx,sy,ex,ey) # all inclusive
  JTRectangle.new(sx, sy, ex-sx, ey-sy)
end

class JTTColor
  @@colornr=1
  attr_reader :color_attr, :name
  def initialize(name,fg,bg,cattr,ncattr)
    #order is name, foreground, background, attribute for color,
    #         attribute for noncolor
    @name=name
    @fg=fg; @bg=bg; @cattr=cattr; @ncattr=ncattr
    @color_attr=nil
    @myid=@@colornr
    @@colornr+=1
  end
  def recompute
    if JTTui.colortui
      # colors and attributes
      JTCur.init_pair @myid,@fg,@bg
      @color_attr=JTCur.color_pair(@myid)|@cattr
    else
      # only attributes if no color
      @color_attr=@ncattr
    end
    eval "def JTTui.#{@name};#{@color_attr};end"
    self
  end
end


# subclass this to get your own custom window class
class JTTWindow
  ALIGN_FREE=0
  ALIGN_CLIENT=1
  ALIGN_TOP=2
  ALIGN_BOTTOM=3
  ALIGN_LEFT=4
  ALIGN_RIGHT=5
  ALIGN_CENTERX=6
  ALIGN_CENTERY=7
  ALIGN_CENTER=8
  attr_reader :align, :name, :parent, :subwindows, :visible, :color, :cursor
  attr_accessor :userfocus
  def initialize(parent, name, x, y, w, h, align=ALIGN_FREE, visible=true)
    parent=JTTui.rootwindow unless parent
    unless parent
      raise JTTWindowException,
	"Cannot create window because root window does not exist", caller
    end
    @parent=parent; @name=name
    @align=align; @visible=visible
    @placement=JTRectangle.new x, y, w, h
    @clientarea=computeclientarea
    @subwindows=[]
    @userfocus=false
    @closed=false
    @color=JTTui.color_basic
    @cursor=nil
    @atclose=[]
    userinit
    resizedself
    parent.add_child self
  rescue; reraise
  end
  def userinit
    # to be overridden by subclasses, it is called from initialize
  end
  def closed?
    @closed
  end
  def close
    @closed=true
    @parent.del_child self if @parent
    @atclose.each {|m| m.call}
    # duplication of subwindows is need because 'each' would be confused about
    # subwindows change in @parent.del_child call
    @subwindows.dup.each {|w| w.close}
    addmessage @parent, :paint if @parent
    delmessages self
    JTTui.clearpos self
  end
  def runatclose(&block) # associated block will be executed at window close
    @atclose << Proc.new(&block)
  end
  def add_child(w)
    addmessage @subwindows.last, :lostfocus
    @subwindows << w
    addmessage w, :gotfocus
    addmessage w, :paint
  end
  def del_child(w)
    w.lostfocus if @subwindows.last==w
    @subwindows.delete w
    addmessage @subwindows.last, :gotfocus
  end
  def up_child(w)
    return if @subwindows.last==w
    addmessage @subwindows.last, :lostfocus
    @subwindows.delete w
    @subwindows << w
    addmessage @subwindows.last, :gotfocus
    addmessage w, :paint
  end
  def down_child(w)
    return if @subwindows.first==w
    addmessage @subwindows.last, :lostfocus
    @subwindows.delete w
    @subwindows=[w] + @subwindows
    addmessage @subwindows.last, :gotfocus
    wp=w.placement
    @subwindows.each{|s|
      addmessage s, :paint if s.placement.crop(wp)
    }
  end
  def up
    @parent.up_child self if @parent
  end
  def down
    @parent.down_child self if @parent
  end
  def gotfocus
  end
  def lostfocus
  end
  def paint
    return unless @visible
    return if @closed
    begin
      paintcontext {|pc| self.paintself pc }
    rescue # FIXME Object ??
      debug $!
      raise
    end
    @subwindows.each{|w| 
      w.paint if w.visible
    }
  end
  def paintself(pc)
    # to be overridden
    # before painting itself call super(pc) if you want paint inheritance
    # pc is current paint context object
    delmessages self,:paint
    # enable this to see how windows are painted:
    #
    #pc.fillrect 0, 0, w, h, ?\s.ord|JTTui.color_inactive_cur
    #JTCur.refresh
    #sleep 0.2
    #
    pc.fillrect 0, 0, w, h, ?\s.ord|@color
    pc.move 0,0
  end
  # associated code block will get paint context object
  # note: it is not called if window is not visible
  def paintcontext
    return if not @visible
    arx,ary,arect=JTTui.abswindowpos self
    return unless arect
    oldcursorpos=JTCur.getx,JTCur.gety
    pc=JTTPaintContext.new(arx, ary, arect)
    yield pc
    @cursor=pc.cursor
    if @cursor
      if self != JTTui.activewindow
	JTCur.move(*@cursor)
	c=(JTCur.inch & (JTCur.attr_chartext | JTCur.attr_altcharset)) |
	  JTTui.color_inactive_cur
	JTCur.move(*@cursor)
	JTCur.addch c
      else
	JTCur.move(*@cursor)
      end
    end
    if self != JTTui.activewindow
      JTCur.move(*oldcursorpos)
    end
  rescue # FIXME Object ??
    debug $!
    raise
  end
  # call this after resizing this window
  def resizedself
    resized
    addmessage @parent, :paint
  end
  # call this after changing client area
  def resizedclient
    resized
    addmessage self, :paint
  end
  # this is called recursively and from resizedself
  def resized
    # note: paint after resize is done in resizedself -> just resize
    return if @closed # don't bother if window is closed
    case align
    when ALIGN_CLIENT
      @placement.set 0, 0, @parent.clientw, @parent.clienth
    when ALIGN_TOP
      @placement.set 0, 0, @parent.clientw, @placement.h
    when ALIGN_BOTTOM
      @placement.set(0, @parent.clienth-@placement.h,
		     @parent.clientw, @placement.h)
    when ALIGN_LEFT
      @placement.set 0, 0, @placement.w, @parent.clienth
    when ALIGN_RIGHT
      @placement.set(@parent.clientw-@placement.w, 0,
		     @placement.w, @parent.clienth)
    when ALIGN_CENTERX
      @placement.set((@parent.clientw-@placement.w)/2, @placement.y,
		     @placement.w,@placement.h)
    when ALIGN_CENTERY
      @placement.set(@placement.x, (@parent.clienth-@placement.h)/2,
		     @placement.w,@placement.h)
    when ALIGN_CENTER
      @placement.set((@parent.clientw-@placement.w)/2,
		     (@parent.clienth-@placement.h)/2,
		     @placement.w,@placement.h)
    when ALIGN_FREE
      # no op
    else
      raise JTTWindowException,
	"Unknown align value", caller[1..-1]
    end
    @clientarea=computeclientarea
    JTTui.clearpos self
    @subwindows.each {|w| w.resized}
  end
  # to get border space, override computeclientarea method
  # call resizedclient if client area was
  #  changed without change to position and size
  def clientx; @clientarea.x end
  def clienty; @clientarea.y end
  def clientw; @clientarea.w end
  def clienth; @clientarea.h end
  def clientex; @clientarea.ex end
  def clientey; @clientarea.ey end
  def computeclientarea
    JTRectangle.new 0, 0, w, h
  end
  # placement is duplicated, programs may depend on duplication
  def placement; @placement.dup end
  def placement=(pl)
    unless pl.kind_of?(JTRectangle)
      raise JTTWindowException,
	"Only JTRectangle can be assigned to placement", caller
    end
    @placement=pl;  resizedself
  end
  def x; @placement.x end
  def y; @placement.y end
  def w; @placement.w end
  def h; @placement.h end
  def x=(v); @placement.x=v; resizedself end
  def y=(v); @placement.y=v; resizedself end
  def w=(v); argfixpos v; @placement.w=v; resizedself end
  def h=(v); argfixpos v; @placement.h=v; resizedself end
  def align=(v); argfixpos v; @align=v; resizedself end
  def visible=(v)
    if @visible ^ v
      @visible=v
      @parent.paint
    end
  end
  def color=(v); @color=v; addmessage self, :paint end
  def argfixpos(v)
    unless v.kind_of?(Integer) and v >= 0
      raise JTTWindowException,
	"Argument must be positive Fixnum", caller[1..-1]
    end
  end
  def addmessage(*msg)
    JTTui.addmessage(*msg)
  end
  def delmessages(*msg)
    JTTui.delmessages(*msg)
  end
  def each_parent
    p=self.parent
    while p
      yield p
      p=p.parent
    end
  end
  def parents_array
    result=[]
    each_parent{|p| result << p}
    result
  end
  def all_subwindows_array
    # note: subwindows are sorted from deepest to 1-level deep
    result=[]
    forallsubwindows{|s| result << s}
    result
  end
  def forallsubwindows(&block) # iterate over all subwindows (recursively)
    # note: block must not change subwindows array, use forallsubwindowssafe
    #       otherwise
    wl=@subwindows
    wl.each{|x| x.forallsubwindows(&block); block.call x}
  end
  def forallsubwindowssafe(&block) # iterate over all subwindows (recursively)
    # block may change subwindows arrays without effect on iteration
    wl=all_subwindows_array
    wl.each{|x| block.call x}
  end
end

class JTTPaintContext
  attr_reader :cursor
  def initialize(x,y,r)
    # x,y is top left corner of window (may be outside clipping rectangle r)
    @tlabsx=x; @tlabsy=y
    @r=r
    @shrinkstack=[] # for nested shrinkpaintarea
    JTCur.setclip r.x, r.y, r.ex, r.ey
    JTCur.move @tlabsx, @tlabsy
    JTCur.attrset JTTui.color_basic
    @cursor=nil
  end
  def shrinkpaintarea(dx,dy,rx,ry,rw,rh)
    # make paint area smaller
    # If block is supplied then pc with shrinked area as parameter is passed
    # and after block is done, previous area is restored.
    # Otherwise undoing shrink is not possible. 
    oldr=@r
    if block_given?
      @shrinkstack << @r
      @shrinkstack << @tlabsx
      @shrinkstack << @tlabsy
    end
    @tlabsx+=dx
    @tlabsy+=dy
    @r=JTRectangle.new(rx+@tlabsx, ry+@tlabsy, rw, rh).crop(oldr)
    @r=JTRectangle.new(0,0,0,0) unless @r
    JTCur.setclip @r.x, @r.y, @r.ex, @r.ey
    move 0,0
    @userclip=nil
    if block_given?
      yield self
      @tlabsy=@shrinkstack.pop
      @tlabsx=@shrinkstack.pop
      @r=@shrinkstack.pop
      JTCur.setclip @r.x, @r.y, @r.ex, @r.ey
    end
  end
  # paint routines can use this to know where painting is not necessary
  def clippingrectangle
    return @userclip if defined? @userclip and @userclip
    @userclip=@r.x-@tlabsx,@r.y-@tlabsy,@r.w,@r.h
  end
  def move(x, y)
    JTCur.move @tlabsx+x, @tlabsy+y
  end
  def moverel(x, y)
    JTCur.moverel x, y
  end
  def setcursor
    c=JTCur.getx, JTCur.gety
    @cursor=c if @r.include?(*c) 
  end
  def addchar(c) # c is character (Fixnum)   
    JTCur.addch c
  end
  def addstr(s)
    JTCur.addstr s.to_s
  end
  def addstra(s, a)
    JTCur.addstra s.to_s, a
  end
  # addlabelstr hilights characters after '_', use '__' to escape this
  def addlabelstr(s, drawactive, color1, color2, color3, color4)
    JTCur.attrset(drawactive ? color2 : color1)
    sa=s.split '_'
    addstr sa.shift
    while sae=sa.shift
      if sae==''
  addchar(?_.ord|(drawactive ? color2 : color1))
	JTCur.attrset drawactive ? color2 : color1
	addstr sa.shift
      else
	JTCur.attrset drawactive ? color4 : color3
  addchar(sae[0].ord) if sae[0]
	JTCur.attrset drawactive ? color2 : color1
	addstr sae[1..-1]
      end
    end
  end
  # c is character (Fixnum) or String (only first character of it will be used)
  def fillrect(x,y,w,h, c)
    if String === c
      c=c[0]
      unless c
	raise JTTWindowException,
	  "Argument c to fillrect must have at least one character",
	  caller[1..-1]
      end
    end
    JTCur.fillrect @tlabsx+x, @tlabsy+y, @tlabsx+x+w, @tlabsy+y+h, c
  end
  def frame(x,y,w,h)
    w-=2; h-=2
    JTCur.move @tlabsx+x, @tlabsy+y
    JTCur.addch JTCur.acs_ulcorner
    w.times{ JTCur.addch JTCur.acs_hline}
    JTCur.addch JTCur.acs_urcorner
    JTCur.move @tlabsx+x, @tlabsy+y+1
    h.times{
      JTCur.addch JTCur.acs_vline
      JTCur.moverel(w,0)
      JTCur.addch JTCur.acs_vline
      JTCur.moverel(-(w+2),1)
    }
    JTCur.addch JTCur.acs_llcorner
    w.times{ JTCur.addch JTCur.acs_hline}
    JTCur.addch JTCur.acs_lrcorner
  end
  def windowframe(w,color)
    JTCur.attrset color
    frame 0, 0, w.w, w.h
  end
  def attrset(color)
    JTCur.attrset color
  end
  def attron(color)
    JTCur.attron color
  end
  def attroff(color)
    JTCur.attroff color
  end
end

class JTTRootWindow < JTTWindow
  attr_accessor :root_allow_break, :background
  def initialize
    @name='JTTRootWindow'
    @parent=nil
    @subwindows=[]
    @visible=true
    @align=ALIGN_CLIENT
    @closed=false
    @atclose=[]
    @background=32|JTTui.color_background
    @root_allow_break=true
    resized
  end
  def resized
    @placement=JTRectangle.new 0, 0, JTCur.cols, JTCur.lines
    @clientarea=JTRectangle.new 0, 0, w, h
    JTTui.clearpos self
    @subwindows.each {|w| w.resized}
  end
  def paintself(pc)
    delmessages self,:paint
    forallsubwindows{|subw| JTTui.delmessages subw,:paint}
    pc.fillrect 0, 0, w, h, @background # paint some background
  end
  def keypress(key)
    # root window is looking for quit key
    addmessage(nil, :close) if key=='C-c' and @root_allow_break
    addmessage(nil, :paint)
  end
  def mousepress(b,x,y)
    # mouse is actually ignored
  end
  def close
    super
    JTTui._delmessages
    addmessage(nil, :quitrootloop)
    JTTui.clearpos self
  end
end


module JTTui
  extend self
  # intended use of run is
  #
  # JTTui.run {|root_window|
  #             # here, use root window to create subwindows
  #           }
  #
  attr_reader :colortui, :colors, :mq, :timeq
  def run(forcelearn=false)
    JTKey.init_key(forcelearn)
    @colors=[
      # background - root window color
      JTTColor.new('color_background',JTCur.color_white,JTCur.color_black,0,0),
      # basic window color,inactives
      JTTColor.new('color_basic',JTCur.color_black,JTCur.color_white,0,0),
      # active controls
      JTTColor.new('color_active',JTCur.color_black,JTCur.color_cyan,0,
		   JTCur.attr_bold),
      # inactive buttons hilighted
      JTTColor.new('color_inactive_hi',JTCur.color_yellow,JTCur.color_white,
		 JTCur.attr_bold,JTCur.attr_bold),
      # active controls hilighted
      JTTColor.new('color_active_hi',JTCur.color_yellow,JTCur.color_cyan,
		 JTCur.attr_bold,0),
      # inactive cursor
      JTTColor.new('color_inactive_cur',JTCur.color_red,JTCur.color_cyan,
		 JTCur.attr_bold,0),
      # editable fields normal
      JTTColor.new('color_edit',JTCur.color_yellow,JTCur.color_blue,
		 JTCur.attr_bold,0),
      # editable fields normal, hilight
      JTTColor.new('color_edit_hi',JTCur.color_red,JTCur.color_cyan,
		 0,JTCur.attr_bold),
      # editable fields hex hilight
      JTTColor.new('color_edit_hex',JTCur.color_green,JTCur.color_blue,
		 JTCur.attr_bold,JTCur.attr_dim),
      # editable fields disabled
      JTTColor.new('color_edit_dis',JTCur.color_white,JTCur.color_blue,0,0)
    ]

    # mq is array of messages, each message
    # is array of target object, method identifier and optional parameters
    # object may be nil for root window, if object does not respond to message
    # its parents are tried, if object want to filter some message it must call
    # parent for messages it does not want
    # messages are added by addmessage function
    @mq=[]
    # message queue for paint messages is separated for performance reasons
    @mqpaint=[]
    # time events queue
    @timeq=[]
    # mousecapture is stack of windows that requested to capture mouse
    # current capturing window is last entry
    # if there is no capturing window, mouse events are sent to window
    # which is visible at mouse position
    @mousecapture=[]
    # modalwindows is stack of modal windows
    # mouse events can go only to last entry or its subwindows
    @modalwindows=[]
    @abswpos={}
    @delmh={}
    begin
      curinitseq true
      paint!
      @root=JTTRootWindow.new
      @activewindow=@root
      trap('WINCH'){
	oldstate=Thread.critical
	Thread.critical=true
	curdoneseq
	curinitseq
	# make root window full redraw
	addmessage nil, :resized
	Thread.critical=oldstate
      }
      catch :quitrootloop do
	yield @root if block_given?
	messageloop
      end
    ensure
      trap 'WINCH','DEFAULT'
      curdoneseq
      JTKey.close_key
    end
  end
  def curinitseq(suppressdraw=false)
    JTCur.init_screen
    JTCur.cbreak
    JTCur.noecho
    JTCur.nonl
    JTCur.raw
    if JTCur.has_colors?
      # change ^ to false to see black and white mode even on color terminal
      JTCur.start_color
      @colortui=true
    else
      @colortui=false
    end
    @colors.each{|c| c.recompute}
    JTKey.reenablemouse
    addmessage nil, :paint unless suppressdraw
    JTCur.refresh
  end
  def curdoneseq
    JTCur.nl
    JTCur.echo
    JTCur.nocbreak
    JTCur.noraw
    JTCur.close_screen
  end
  def after(sec,&block)
    eventtime=Time.now+sec
    @timeq << [eventtime,block] # FIXME: insert to right place would be better
    @timeq.sort!{ |a,b| a[0]<=>b[0] }
  end
  def addmessage(*msg)
    # message must be addressed to nil or JTTWindow descendant
    msg[0]=@root unless msg[0]
    unless JTTWindow===msg[0]
      raise JTTWindowException,
	"addmessage: invalid target object: #{msg[0].inspect}",caller
    end
    unless Symbol===msg[1]
      raise JTTWindowException,
	"addmessage: invalid message: #{msg[1].inspect}",caller
    end
    if msg[1]==:paint
      @mqpaint << msg
    else
      @mq << msg
    end
  end
  def delmessages(target, event=nil)
    if event
      mwh=@delmh[target]
      case mwh
      when NilClass
	@delmh[target]=[event]
      when Array
	mwh << event
      end
    else
      @delmh[target]=true
    end
  end
  def _delmessages
    mwh=nil
    [@mq,@mqpaint].each{ |queue|
      queue.delete_if{ |x|
	mwh=@delmh[x[0]]
	case mwh
	when TrueClass
	  true
	when Array
	  mwh.include? x[1]
	else
	  false
	end
      }
    }
    @delmh={}
  end
  def getmessage
    loop {
      _delmessages if @delmh.length>0
      msg=@mq.shift
      msg=@mqpaint.shift unless msg
      if msg
	if msg[1]==:paint
	  msgpar=msg[0].parents_array+[msg[0]]
	  if @mq.find{|m| m[1]==:paint and msgpar.include? m[0]}
	    # ignore paint message if parent of its target
	    # is planned to be painted
	    next
	  end
	end
	return nil if msg[1]==:quitloop
	throw :quitrootloop if msg[1]==:quitrootloop
	return msg
      end
      paint!
      maxtimeout=nil
      unless @timeq.empty?
	maxtimeout=timeq[0][0]-Time.now
	maxtimeout=0 if maxtimeout<0
      end
      key=JTKey.readkey(maxtimeout) # read keyboard or mouse
      if key=='' and maxtimeout
	# if timeout event is ready
	mytime=Time.now
	while not @timeq.empty? and @timeq[0][0]<mytime
	  # uncomment to measure time delay between wanted and
	  # the time before and after of event
	  # debug 'pre',Time.now-@timeq[0][0]
	  @timeq[0][1].call
	  # debug 'post',Time.now-@timeq[0][0]
	  @timeq.shift
	end
	next
      end
      if Array===key
	if @mousecapture.empty?
	  mw=findwindowat key[1],key[2]
	  unless @modalwindows.empty?
	    mwl=@modalwindows.last
	    mwp=mw.parents_array + [mw]
	    unless mwp.include? mwl
	      mw=nil # mouse event outside modal window
	    end
	  end
	else
	  mw=@mousecapture.last
	end
	if mw
	  mwax,mway=abswindowpos mw
	  return [mw, :mousepress, key[0], key[1]-mwax, key[2]-mway]
	end # loop otherwise
      else
	return [activewindow, :keypress, key]
      end
    }
  end
  def peekmessage
    # you should not use this, if you think there is valid reason for it
    # email to JT, I plan to remove it otherwise
    @mq[0]
  end
  def sendmessage(msg)
    unless msg
      raise JTTWindowException,
	"Invalid message #{msg}", caller
    end
    obj=msg.shift
    begin
      if obj.respond_to? msg[0]
	obj.send(*msg)
	break
      end
      obj=obj.parent
    end until obj == nil
  end
  def messageloop
    while msg=getmessage
      sendmessage msg
    end
  end
  def rootwindow
    @root
  end
  def activewindow
    w=rootwindow
    w=w.subwindows.last until w.subwindows == []
    w
  end
  def activewindow=(w)
    while w
      w.up
      w=w.parent
    end
  end
  def addmodalwindow(w)
    @modalwindows << w
  end
  def removemodalwindow
    @modalwindows.pop
  end
  def capturemouse(w)
    @mousecapture << w
  end
  def releasemouse
    w=@mousecapture.pop
  end
  # translate window coordinates to
  #  absolute coordinates of top left corner and
  #  coordinates of visible rectange wrt parents
  #  arx,ary,arect=JTTui.abswindowpos self
  # return nil if it is not visible
  def abswindowpos(w)
    res=@abswpos.fetch w,false
    return res unless res==false
    res=_abswindowpos(w)
    @abswpos[w]=res
  end
  def clearpos(w)
    @abswpos.delete w
  end
  def _abswindowpos(w)
    wlist=[w]
    while w=w.parent do
      wlist << w
    end
    w=wlist.pop # w is now root window
    r=w.placement;
    arx=r.x; ary=r.y
    until wlist.empty?
      clr=JTRectangle.new(w.clientx+arx, w.clienty+ary, w.clientw, w.clienth)
      arx=clr.x
      ary=clr.y
      r=r.crop clr
      return nil unless r      
      w=wlist.pop
      wr=JTRectangle.new(w.x+arx, w.y+ary, w.w, w.h)
      arx+=w.x
      ary+=w.y
      r=r.crop wr
      return nil unless r
    end
    return arx, ary, r
  end
  def findwindowat(x,y)
    w=@root
    arx,ary=0,0
    loop {
      arx+=w.x+w.clientx; ary+=w.y+w.clienty
      return w if arx+w.clientw<=x
      return w if ary+w.clienth<=y
      wlr=w.subwindows.dup.reverse
      wq=wlr.find{ |wx|
	wx.placement.include? x-arx,y-ary
      }
      return w unless wq
      w=wq
    }
  end
  def findwindowbyname(name)
    found=nil
    @root.forallsubwindows{|w|
      if w.name==name
	found=w
	break
      end
    }
    found
  end
  def beep
    JTCur.beep
  end
  def paint!
    JTCur.refresh
  end
  def forcerepaint!
    JTCur.clear
    @root.paint
    JTCur.refresh
  end
end

