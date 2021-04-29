# -*- coding: utf-8 -*-
#
# Jakub Travnik's textmode user interface
# standard window objects
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

require "jttui/jttui"
require "observer"

#
# see doc/Documentation/starting-guide.txt for intro how to use this stuff
#

# working content:
# (JTTWindow)
#  +--JTTFrame
#  |  +--JTTDialog
#  +--JTTWidget
#     +--JTTWLabel
#     +--JTTWFocusable
#     |  +--JTTWButton
#     |  +--JTTWCheckbox
#     |  +--JTTWRadiogroup
#     |  +--JTTWEditline
#     |  |  +--JTTWEditpass
#     |  +--JTTWScrollbox
#     |  +--JTTWList (abstract vertical list class)
#     |  |  +--JTTWListLabels
#     |  |  +--JTTWListButtons
#     |  |  +--JTTWListCheckboxes
#     |  |  +--JTTWTree
#     |  +--JTTWScrollbar
#     |  +--JTTWMenu (planned)
#     +--JTTWGrid
# JTTWMessagebox
#
# module JTWHilightletter (common stuff for hilight by letter)
# JTEditor        - this class is independent on JTTui,
#                   except for JTTui.beep and key names
# JTScroller      - independent on JTTui,
#                   except drawing and mouse reaction functions
# JTTreeNode      - independent on JTTui, data part of JTTWTree and JTWMenu
# +--JTTWTreeNode - subclass with information about expansion of subtree
# |  +--JTTWTreeNodeLabel
# |  |            - subclass with drawing capatibilities
# |  +--JTTWTreeNodeCheckbox
# |               - subclass with drawing capatibilities and state
# +--JTTWMenuItem - (planned) subclass for menu-tree items
#

#other planned widgets:
# fileviewer (highest priority)
# htmlviewer
# editmask, editarea  (lowest priority)

#exceptions:
class InvalidTabWindow < RuntimeError
end

class JTTFrame < JTTWindow
  attr_reader :caption

  def initialize(*params, &block) # last parameter is caption
    @caption = params.pop   # eat it
    super(*params, &block)
  end

  def paintself(pc)
    super
    pc.windowframe self, @color
    unless @caption == ""
      pc.move 2, 0
      pc.addstr @caption
    end
  end

  def computeclientarea
    JTRectangle.new 1, 1, [w - 2, 0].max, [h - 2, 0].max
  end

  def caption=(v); @caption = v; addmessage self, :paint end
end

class JTTDialog < JTTFrame
  attr_accessor :defaultbutton, :cancelbutton, # buttons must respond to action
                :tabstop

  def initialize(*params, &block)
    super(*params, &block)
    @tabstop = []
    @tabid = -1 # no window is focused
    @tabidold = -1 # no previous window
    @defaultbutton = nil
    @cancelbutton = nil
    @registeredkeys = {}
    JTTui.addmodalwindow self
  end

  def ordertabs
    return unless @tabid
    return if @tabid == -1
    return if @tabstop.length == 0
    if @tabidold != @tabid
      if @tabidold >= 0 and @tabidold < @tabstop.length
        addmessage @tabstop[@tabidold], :lostfocus
      end
    end
    w = @tabstop[@tabid]
    begin
      w.up
      w = w.parent
    end until w == self
    if @tabidold != @tabid
      @tabidold = @tabid
      addmessage @tabstop[@tabid], :gotfocus
    end
  end

  def addtabstop(w)
    @tabstop << w
    if @tabid == -1
      @tabid = 0
      ordertabs
    end
  end

  def deltabstop(w)
    idx = @tabstop.index w
    if idx
      @tabstop.delete_at idx
      if @tabid >= idx
        @tabid -= 1
        @tabid = 0 if @tabid < 0
        ordertabs
      end
    else
      # should we ignore this?
    end
  end

  def nexttab
    @tabid += 1
    @tabid = 0 if @tabid >= @tabstop.length
    ordertabs
  end

  def prevtab
    @tabid -= 1
    @tabid = @tabstop.length - 1 if @tabid < 0
    ordertabs
  end

  def settab(w)
    idx = @tabstop.index w
    unless idx
      raise InvalidTabWindow, "invalid window for tab: '#{defined?(w.name) ? w.name : "nil"}'"
    end
    @tabid = idx
    ordertabs
  end

  def del_child(w)
    deltabstop(w) if @tabstop.include? w
    super
  end

  def close
    super
    JTTui.removemodalwindow
  end

  def registerkey(window, keyname)
    return unless keyname
    @registeredkeys[keyname] = window
  end

  def unregisterkey(window, keyname)
    w = @registeredkeys[keyname]
    @registeredkeys.delete keyname if w == window
  end

  def keypress(key)
    w = @registeredkeys[key]
    if w
      begin
        settab w
      rescue InvalidTabWindow
      end
      w.hilightaction
    else
      case key
      when "C-i", "down", "right"
        nexttab
      when "M-C-i", "up", "left"
        prevtab
      when "C-m", "C-j"
        if @defaultbutton
          settab @defaultbutton
          @defaultbutton.action
        end
      when "esc"
        if @cancelbutton
          settab @cancelbutton
          @cancelbutton.action
        end
      else
        addmessage @parent, :keypress, key
      end
    end
  end
end

class JTTWidget < JTTWindow
  attr_reader :parentdialog, :color_hi
  attr_accessor :block

  def initialize(*params, &block)
    @block = block
    @parentdialog = nil
    p = params[0]
    while p
      if p.class <= JTTDialog
        @parentdialog = p
        break
      end
      p = p.parent
    end
    raise "no parent is dialog" unless @parentdialog
    @color_hi = JTTui.color_inactive_hi
    super(*params, &block)
  end

  def color_hi=(v); @color_hi = v; addmessage self, :paint end
end

module JTWHilightletter
  # this is mix-in for hilighted letters like in label
  # all routines of it and external variables are prefixed with hl_
  # except for hilightaction which is handler to pressed keys
  # and except hilightme which is to be called from hilightaction where useful
  extend self

  def hl_addone(keyname) # add one letter
    unless defined? @hl_letters
      runatclose { self.hl_removeall }
      @hl_letters = []
    end
    @parentdialog.registerkey self, keyname
    @hl_letters << keyname
  end

  def hl_removeall # remove all registered letters
    return unless defined? @hl_letters
    @hl_letters.each { |keyname| @parentdialog.unregisterkey self, keyname }
  end

  def hl_removeone(keyname) # remove requested letter
    @parentdialog.unregisterkey self, keyname
  end

  def hl_scan(text)
    # scan text for first letter, return nil if none
    # it is letter after _ but not __
    fhl = /[^_]_([^_])|\A_([^_])/n.match text
    return nil unless fhl
    fhl = fhl[1] ? fhl[1] : fhl[2]
    fhl =~ /[a-zA-Z0-9~`!@\#$%^&*()+=\/.\\-]/n ? fhl.downcase : nil
  end

  def hl_newfromtext(text)
    # remove all registered letters and try to set new one if exist
    hl_removeall
    letter = hl_scan(text)
    hl_addone letter if letter
  end

  def hl_countchars(text)
    # count number of displayed characters
    count_ = 0; count__ = 0
    i = 0
    loop do
      i = text.index(/[^_]_[^_]|\A_[^_]/n, i)
      break unless i
      count_ += 1
      i += 1
    end
    i = 0
    loop do
      i = text.index(/__/n, i)
      break unless i
      count__ += 1
      i += 2
    end
    res = (text.length - count_ - count__)
    return res
  end

  def hilightaction
    # to be overridden, this is executed when user press associated key
  end

  def hilightme # to be called from hilightaction where useful
    @parentdialog.settab self
  end
end

class JTTWLabel < JTTWidget
  include JTWHilightletter
  @@wordcharmap = ""
  attr_reader :caption, :breaklines, :autowrap

  def initialize(*params, &block)
    @autowrap = true
    @caption = params.pop # last parameter is caption
    if @@wordcharmap == ""
      @@wordcharmap = "\0" * 256
      (?a.ord..?z.ord).each { |x| @@wordcharmap[x] = "1" }
      (?A.ord..?Z.ord).each { |x| @@wordcharmap[x] = "1" }
      (?0.ord..?9.ord).each { |x| @@wordcharmap[x] = "1" }
      (128..255).each { |x| @@wordcharmap[x] = "1" }
      @@wordcharmap[?_.ord] = "1"
    end
    super(*params, &block) # breakwords is called here from super->resizedself
    @hilightaction = @block # hilight letter action block
  end

  def autowrap=(v)
    @autowrap = v
    breakwords
    addmessage self, :paint
  end

  def hilightaction
    @hilightaction.call self if @hilightaction
  end

  def mousepress(b, x, y)
    hilightaction if b == 4
  end

  def cutnextword(text)
    nextnonword = text.index(@@nonwordchar)
    nextword = text.index(@@wordchar)
  end

  def resizedself
    super
    breakwords
  end

  def breakwords
    # first find first hilighted letter and register it
    hl_newfromtext @caption
    # now break words
    textlines = @caption.split "\n"
    maxwidth = self.w
    @breaklines = []
    unless @autowrap # do not wrap if not wanted
      @breaklines = textlines
      return
    end
    textlines.each { |textline| # break each paragraph
      ptr = 0; ptrend = 0
      wordhead = 0; wordtail = 0 # optimalization: avioding variables in inner cycle
      tllength = textline.length
      while ptr < tllength
        ptrend = ptr + maxwidth
        if ptrend >= tllength # if current rest of line is shorter than max width
          @breaklines << textline[ptr, maxwidth]
          break
        end
        unless @@wordcharmap[textline[ptrend]] == "1"
          # no word at ptrend, breaking
          @breaklines << textline[ptr...ptrend]
          ptrend += 1 if textline[ptrend] == ?\s.ord
          ptr = ptrend
          next
        end
        wordhead = ptrend; wordtail = ptrend
        while wordhead >= ptr and @@wordcharmap[textline[wordhead]] == "1"
          wordhead -= 1
        end
        wordhead += 1
        while wordtail < tllength and @@wordcharmap[textline[wordtail]] == "1"
          wordtail += 1
        end
        wlength = wordtail - wordhead
        # ptrend points to place where new line should start, but word is there
        # now we have these pointers:
        #        somelongword
        # ptr^   ^    ^      ^
        #     head  ptrend   tail
        # if length of the word (wlength) is longer than whole line, it will be
        # broken in middle (ptrend)
        # else line will end before the word (wordhead)
        if wlength > maxwidth
          @breaklines << textline[ptr...ptrend]
          ptr = ptrend
        else
          if wordhead > ptr and textline[wordhead - 1] == ?\s.ord
            @breaklines << textline[ptr...wordhead - 1]
          else
            @breaklines << textline[ptr...wordhead]
          end
          ptr = wordhead
        end
      end
    }
  end

  def paintself(pc)
    super
    crx, cry, crw, crh = pc.clippingrectangle
    (cry...([cry + crh, @breaklines.length].min)).each { |linenr|
      pc.move 0, linenr
      pc.addlabelstr @breaklines[linenr], false, @color, 0, @color_hi, 0
    }
  end

  def caption=(v); @caption = v; breakwords; addmessage self, :paint end
end

class JTTWFocusable < JTTWidget
  attr_reader :color_active, :color_active_hi

  def initialize(*params, &block)
    @focus = false
    @holdmouse = false
    super(*params, &block)
    @color_active = JTTui.color_active
    @color_active_hi = JTTui.color_active_hi
  end

  def color_active=(v); @color_active = v; addmessage self, :paint end
  def color_active_hi=(v); @color_active_hi = v; addmessage self, :paint end

  def focused?
    @focus
  end

  def gotfocus
    @focus = true
    addmessage self, :paint
  end

  def lostfocus
    if @holdmouse == true
      JTTui.releasemouse
      @holdmouse = false
    end
    @focus = false
    addmessage self, :paint
  end

  def mousepress(b, x, y)
    case b
    when 1
      @holdmouse = true
      JTTui.capturemouse self
      if @parentdialog and @parentdialog.tabstop.index self
        addmessage @parent, :settab, self
      end
      mousedown x, y
    when 4
      @holdmouse = false
      JTTui.releasemouse
      mouseclick x, y
    end
  end

  def mouseclick(x, y) # no op
  end

  def mousedown(x, y) # no op
  end
end

class JTTWButton < JTTWFocusable
  include JTWHilightletter
  attr_reader :caption

  def initialize(*params, &block)
    @caption = params.pop # last parameter is caption
    super(*params, &block)
    hl_newfromtext(@caption)
  end

  def paintself(pc)
    super
    s = "[" + @caption.center(w - 2 + @caption.length - hl_countchars(@caption)) + "]"
    pc.addlabelstr s, focused?,
      @color, @color_active, @color_hi, @color_active_hi
    pc.move 1, 0
  end

  def caption=(v)
    @caption = v; hl_newfromtext(@caption); addmessage self, :paint
  end

  def keypress(key)
    case key
    when " ", "C-m", "C-j"
      action
    else
      addmessage @parent, :keypress, key
    end
  end

  def mouseclick(x, y)
    action if @clientarea.include? x, y
    # action only if mouse was depressed at button
  end

  def action # override or give block to new
    @block.call self if @block
  end

  def hilightaction
    action
  end
end

class JTTWCheckbox < JTTWFocusable
  include JTWHilightletter
  attr_reader :caption, :state, :states, :statesstring

  def initialize(*params, &block)
    @states = 2
    @statesstring = " x?"
    @state = 0
    @caption = params.pop # last but one parameter is caption
    super(*params, &block)
    hl_newfromtext(@caption)
  end

  def state=(v); @state = v; addmessage self, :paint end

  def states=(v)
    @states = v
    if @state >= @states
      @state = 0
      addmessage @parent, :keypress, key
    end
  end

  def statesstring=(v)
    @statesstring = v
    addmessage @parent, :keypress, key
  end

  def paintself(pc)
    super
    s = "[" + @statesstring[@state].chr + "] " + @caption
    pc.addlabelstr s, focused?,
      @color, @color_active, @color_hi, @color_active_hi
    pc.move 1, 0
  end

  def caption=(v)
    @caption = v; hl_newfromtext(@caption); addmessage self, :paint
  end

  def mouseclick(x, y)
    action if @clientarea.include? x, y
    # action only if mouse was depressed at button
  end

  def keypress(key)
    case key
    when " "
      action
    else
      addmessage @parent, :keypress, key
    end
  end

  def action
    self.state = (@state + 1) % @states
    @block.call self if @block
  end

  def hilightaction
    action
  end
end

class JTTWRadiogroup < JTTWFocusable
  attr_reader :entries, :state, :focusedentry

  def initialize(*params, &block)
    @state = params.pop   # last parameter is default entry or -1
    @entries = params.pop # last but one parameter is array of string
    @focusedentry = 0     # index of focused entry
    super(*params, &block)
  end

  def state=(v); @state = v; addmessage self, :paint end

  def paintself(pc)
    super
    @entries.each_with_index { |text, i|
      pc.move 0, i
      s = "(" + (i == @state ? "*" : " ") + ") " + text
      pc.addlabelstr s, ((@focusedentry == i) and focused?),
                     @color, @color_active, @color_hi, @color_active_hi
    }
    pc.move 1, @focusedentry
  end

  def entries=(v); @entries = v; addmessage self, :paint end

  def focusedentry=(v)
    @focusedentry = (0...@entries.length).clip v
    addmessage self, :paint
  end

  def mousedown(x, y)
    @focusedentry = y
  end

  def mouseclick(x, y)
    action if @clientarea.include? x, y
    # action only if mouse was depressed at button
  end

  def keypress(key)
    case key
    when " "
      action
    when "down"
      if @focusedentry < @entries.length - 1
        self.focusedentry = @focusedentry + 1
      else
        addmessage @parent, :nexttab
      end
    when "up"
      if @focusedentry > 0
        self.focusedentry = @focusedentry - 1
      else
        addmessage @parent, :prevtab
      end
    else
      addmessage @parent, :keypress, key
    end
  end

  def action
    self.state = @focusedentry
    @block.call self if @block
  end
end

module JTClipboard
  extend self
  MAX_CLIPS = 5
  @clips = []

  def addclip(s, addtolast = false)
    (addtolast ? @clips.last : @clips) << s
    @clips.shift if @clips.length > MAX_CLIPS
  end

  def getclip
    @clips.last
  end

  def getprevclip
    top = @clips.pop
    @clips = [top] + @clips
    getclip
  end

  attr_reader :clips
end

class JTEditor
  # FIXME: it might be good idea not to use string for all text
  #        because when text have size of 1MB inserting one character
  #        at start is time consuming operation, because all million characters
  #        must be shifted
  #        Solution to this might be array of lines
  #        made as: lines=alltext.split "\n";lines << '' if alltext[-1]=="\n"
  #        then inserting character would take time proportional to length
  #        of that line
  #        this would simplify line operations such as movetoup, but
  #        make operations over multiple lines harder i.e. movetoright, movetoeow
  #        I will consider changing this when jttui* will become stable
  include Observable
  include DelayedNotify
  INSERT = 1
  OVERWRITE = 2
  QUOTE_NONE = 0
  QUOTE_VERBATIM = 1
  QUOTE_HEX = 2
  attr_reader :text, :cursor, :mark, :mode, :quoting

  def initialize(defaulttext = "")
    @text = defaulttext
    @cursor = 0
    resetmark # no mark by default
    @mode = INSERT
    @quoting = QUOTE_NONE
    @hex = ""
    delayednotify_init { changed; notify_observers }
    # last operation to recognize consecutive kills
    # and append them to one clipboard entry
    @last = nil
  end

  def beep
    JTTui.beep
  end

  def text=(v)
    @text = v
    @cursor = (0..@text.length).clip @cursor
    resetmark
    notify; @last = :text=
  end

  def cursor=(v)
    @cursor = (0..@text.length).clip v
    notify; @last = :cursor=
  end

  def setmark(position = @cursor)
    @mark = (0..@text.length).clip position; @last = :setmark
  end

  def resetmark
    @mark = nil
  end

  def typequit
    resetmark
    @mode = INSERT
    @quoting = QUOTE_NONE
    @hex = ""
    @notifyblocked = 0
    @last = nil
    notify; beep
  end

  def switchinsert # switch modes and under linux console set cursor shape
    case @mode
    when INSERT
      @mode = OVERWRITE
      print "\e[?6c" if ["linux", "console"].include? ENV["TERM"]
    when OVERWRITE
      @mode = INSERT
      print "\e[?2c" if ["linux", "console"].include? ENV["TERM"]
    end
  end

  def typestring(s)
    over = (@mode == OVERWRITE) ? s.length : 0
    @text[@cursor, over] = s
    @mark = nil
    @cursor += s.length
    notify; @last = :typestring
  end

  def backspace
    if @cursor > 0
      @cursor -= 1
      @text[@cursor, 1] = ""
      @mark = nil
      notify
    else
      beep
    end
    @last = :backspace
  end

  def delete
    if @cursor < @text.length
      @text[@cursor, 1] = ""
      @mark = nil
      notify
    else
      beep
    end
    @last = :delete
  end

  def movetosot # start of text
    @cursor = 0
    setmark
    notify; @last = :movetosot
  end

  def movetoeot # end of text
    @cursor = @text.length
    setmark
    notify; @last = :movetoeot
  end

  def movetosol # start of line
    pos = @text.rindex("\n", @cursor - 1)
    if pos
      @cursor = pos + 1
    else
      @cursor = 0
    end
    notify; @last = :movetosol
  end

  def movetoeol # end of line
    pos = @text.index("\n", @cursor)
    if pos
      @cursor = pos
    else
      @cursor = @text.length
    end
    notify; @last = :movetoeol
  end

  def movetoleft # left by one character
    if @cursor > 0
      @cursor -= 1
      notify
    else
      beep
    end
    @last = :movetoleft
  end

  def movetoright # right by one character
    if @cursor < @text.length
      @cursor += 1
      notify
    else
      beep
    end
    @last = :movetoright
  end

  def getcolumn
    st = @text.rindex("\n", @cursor - 1)
    st = st ? st + 1 : 0 # position of start of this line
    @cursor - st       # current column (0 is leftmost)
  end

  def movetodown # down by one line
    return beep if @cursor == @text.length
    col = [:movetodown, :movetoup].include?(@last) ? @lastcolumn : getcolumn
    @lastcolumn = col
    nlst = @text.index("\n", @cursor)
    nlst = nlst ? nlst + 1 : @text.length    # next line start or eot
    nlend = @text.index("\n", nlst)
    nlend = @text.length unless nlend       # end of next line
    @cursor = [nlst + col, nlend].min
    notify; @last = :movetodown
  end

  def movetoup # up by one line
    return beep if @cursor == 0
    curcol = getcolumn
    col = [:movetodown, :movetoup].include?(@last) ? @lastcolumn : curcol
    @lastcolumn = col
    plend = (@cursor - curcol) - 1                 # end of previous line
    if plend <= 0
      @cursor = 0
    else
      plst = @text.rindex("\n", plend - 1)
      plst = plst ? plst + 1 : 0               # previous line start or 0
      @cursor = [plst + col, plend].min
    end
    notify; @last = :movetoup
  end

  def movetosow # start of word
    return @cursor = 0 if @cursor < 2
    pos = @text.rindex(/[^a-zA-Z0-9\200-\377][a-zA-Z0-9\200-\377]/n, @cursor - 2)
    if pos
      @cursor = pos + 1
    else
      @cursor = 0
    end
    notify; @last = :movetosow
  end

  def movetoeow # end of word
    pos = @text.index(/[a-zA-Z0-9\200-\377][^a-zA-Z0-9\200-\377]/n, @cursor)
    if pos
      @cursor = pos + 1
    else
      @cursor = @text.length
    end
    notify; @last = :movetoeow
  end

  # copy text between cursor and mark to clipboard
  def copyregion(killafter = false, killadd = false)
    return unless @mark
    sel = [@cursor, @mark].sort
    JTClipboard.addclip @text[sel.first...sel.last], killadd
    if killafter
      @text[sel.first...sel.last] = ""
      @cursor = @mark if @cursor > @mark
    end
    resetmark
    notify; @last = :copyregion
  end

  # moves text between cursor and mark to clipboard
  def killregion(killadd = false)
    copyregion true, killadd
    @last = :killregion
  end

  def killto(lkl, &move)
    delayednotify {
      lastbackup = @last
      setmark
      move.call
      @last = lastbackup
      killregion lkl == @last
      @last = lkl
    }
  end

  # moves text between cursor and eol to clipboard, delete line empty
  # consecutive killtoeol calls cumulate to one clipboard entry
  def killtoeol
    char = @text[@cursor, 1]
    if char == "\n"
      killto :killtoeol do movetoright end
    else
      killto :killtoeol do movetoeol end
    end
  end

  def killtoeow
    killto :killtoeow do movetoeow end
  end

  def killtosow
    killto :killtosow do movetosow end
  end

  def yank
    @yankcursorstart = @cursor
    clip = JTClipboard.getclip
    if clip
      typestring clip # notify is done here
    else
      beep # no clip yet
    end
    @last = :yank
  end

  def prevyank
    return beep unless [:yank, :prevyank].include? @last
    @text[@yankcursorstart...@cursor] = ""
    @cursor = @yankcursorstart
    clip = JTClipboard.getprevclip
    if clip
      typestring clip # notify is done here
    else
      beep # no clip yet
    end
    @last = :prevyank
  end

  def transpose
    return beep if @text.length < 2 or @cursor == 0 or @cursor == @text.length
    @text[@cursor - 1], @text[@cursor] = @text[@cursor], @text[@cursor - 1]
    movetoright # notify is done here
    @last = :transpose
  end

  def handlekey(key, rawkey)
    case @quoting
    when QUOTE_VERBATIM
      typestring JTKey.inverselookup(rawkey)
      @quoting = QUOTE_NONE
      return true
    when QUOTE_HEX
      case key
      when "a".."f", "A".."F", "0".."9"
        @hex += key
        if @hex.length == 2
          typestring @hex.hex.chr
          @quoting = QUOTE_NONE
          @hex = ""
        end
        return true
      else
        @quoting = QUOTE_NONE
        @hex = ""
        beep
        return false
      end
    else # QUOTE_NONE
      case key
      when "left", "C-b" then movetoleft
      when "right", "C-f" then movetoright
      when "up", "C-p" then movetoup
      when "down", "C-n" then movetodown
      when "home", "M-<" then movetosot
      when "end", "M->" then movetoeot
      when "ins" then switchinsert
      when "C-g" then typequit
      when "C-a" then movetosol
      when "C-e" then movetoeol
      when "backspace", "C-h" then backspace
      when "del", "C-d" then delete
      when "M-f" then movetoeow
      when "M-b" then movetosow
      when "M-C-h", "M-backspace" then killtosow
      when "M-d" then killtoeow
      when "C-k" then killtoeol
      when "C-@" then setmark
      when "C-w" then killregion
      when "M-w" then copyregion
      when "C-y" then yank
      when "M-y" then prevyank
      when "C-q" then @quoting = QUOTE_VERBATIM
      when "M-q" then @quoting = QUOTE_HEX
      when "C-t" then transpose
      else
        if key.length == 1 and key[0].ord >= 32
          typestring key
          return true
        end
        return false
      end
      return true
    end
  end

  def movementkey?(key)
    ["left", "C-b", "right", "C-f",
     "up", "C-p", "down", "C-n",
     "home", "M-<", "end", "M->",
     "C-a", "C-e",
     "M-f", "M-b",
     "C-@", "M-w", "C-g"].include? key
  end
end

# keys for JTEditor, most are same as in emacs
# current exceptions: C-u is undo (C-x u in emacs)
#  most of other - verbatim, otherwise ignored
#  left=C-b      - left by one character
#  right=C-f     - right by one character
#  down=C-n      - one line down
#  up=C-p        - one line up
#  home=M-<      - go to start of text
#  end=M->       - go to end of text
#  C-a           - go to start of line
#  C-e           - go to end of line
#  \177=C-h      - delete previous character
#  del=C-d       - delete next character
#  M-f           - go to end of word
#  M-b           - go to start of word
#  M-\177=M-C-h  - delete from here to start of current word (clipboard)
#  M-d           - delete from here to end of current word   (clipboard)
#  C-k           - kill to end of line                       (clipboard)
#  C-@           - set mark (C-@ may/have to be typed as C-SPC)
#  C-w           - kill text from mark to here               (clipboard)
#  M-w           - save text from mark to here               (clipboard)
#  C-y           - yank from clipboard                       (clipboard)
#  M-y           - after yank tries previous yanked text     (clipboard)
#  C-t           - transpose (swap) last two characters
#  C-q           - qoute next character
#  M-q           - read character in hex
#  C-u           - undo                   FIXME: not yet implemented

class JTTWEditline < JTTWFocusable
  attr_reader :enabled, :editor
  attr_accessor :displaytransformer

  def initialize(*params, &block)
    @enabled = params.pop # last parameter is editing enabler
    @editor = JTEditor.new params.pop # last but one parameter is default text
    @editor.add_observer self
    @viewstart = 0
    super(*params, &block)
    @color = JTTui.color_edit
    @translatetab = {
      "up" => "ignore",
      "down" => "ignore",
      "home" => "C-a",
      "end" => "C-e",
      "C-i" => "ignore",
    }
  end

  def update
    addmessage self, :paint
    @block.call self if @block
  end

  def enabled=(v); @enabled = v; addmessage self, :paint end

  def displayashex?(char)
    return true if char.ord < 32
    return true if char.ord == 127
    false
  end

  def getcharwidth(char) # char is one character String
    displayashex?(char) ? 4 : 1
  end

  def getcharwidthat(pos) # if character is out of range, 1 is returned
    char = @editor.text[pos]
    char = 32 unless char
    getcharwidth(char)
  end

  def formatasline(lastviewstart, width)
    len = @editor.text.length
    cur = @editor.cursor
    viewstart = lastviewstart
    if cur < viewstart
      viewstart = [cur, viewstart - width / 4].min
      viewstart = [viewstart, 0].max
    end
    viewend = getviewend(width, viewstart)
    if viewend < cur
      teststart = viewstart + width / 4
      viewend = getviewend(width, teststart)
      if viewend < cur
        viewstart = [cur - width / 4, 0].max
        viewend = getviewend(width, viewstart)
      else
        viewstart = teststart
        viewend = getviewend(width, viewstart)
      end
    end
    return getrelcur(viewstart, cur),
           viewstart, viewstart > 0, viewend < len
  end

  def getrelcur(start, cur)
    relcur = 0
    while start < cur
      relcur += getcharwidthat(start)
      start += 1
    end
    relcur
  end

  def getviewend(width, viewstart)
    viewend = viewstart
    while width > 0
      width -= getcharwidthat(viewend)
      viewend += 1
    end
    if viewend > 0 then viewend - 1 else viewend end
  end

  def getabscur(relcur, viewstart)
    while relcur > 0
      relcur -= getcharwidthat(viewstart)
      viewstart += 1
    end
    viewstart
  end

  def paintself(pc)
    super
    pc.move 0, 0
    editwidth = self.w - 2
    relcursor, @viewstart, leftcont, rightcont =
      formatasline @viewstart, editwidth
    pc.addchar((leftcont ? ?<.ord : ?\s.ord) | (focused? ? JTTui.color_edit_hi : 0))
    viewptr = @viewstart
    viewlen = 0
    marked = @editor.mark ? [@editor.mark, @editor.cursor].sort : [-1, -1]
    color6 = @enabled ? JTTui.color_edit : JTTui.color_edit_dis
    color8 = JTTui.color_edit_hex
    while viewlen < editwidth
      colorA = color6
      colorB = color8
      if marked.first <= viewptr and marked.last > viewptr
        colorA |= JTCur.attr_reverse
        colorB |= JTCur.attr_reverse
      end
      char = @editor.text[viewptr]
      char = @displaytransformer.call(char) if @displaytransformer
      char = ?\s.ord unless char
      if displayashex?(char)
        hexarr = char.divmod 16
        hextab = "0123456789ABCDEF"
        pc.addchar ?<.ord | colorB
        viewlen += 1
        break unless viewlen < editwidth
        pc.addchar hextab[hexarr[0]] | colorB
        viewlen += 1
        break unless viewlen < editwidth
        pc.addchar hextab[hexarr[1]] | colorB
        viewlen += 1
        break unless viewlen < editwidth
        pc.addchar ?>.ord | colorB
      else
        pc.addchar char.ord | colorA
      end
      viewlen += 1; viewptr += 1
    end
    pc.addchar((rightcont ? ?>.ord : ?\s.ord) | (focused? ? JTTui.color_edit_hi : 0))
    pc.move relcursor + 1, 0
    pc.setcursor
  end

  def keypress(key)
    translatedkey = @translatetab[key] # 'ignore' is returned to suppress key
    translatedkey = key unless translatedkey
    if @enabled or @editor.movementkey?(key)
      unless @editor.handlekey translatedkey, key
        addmessage @parent, :keypress, key
      end
    else
      addmessage @parent, :keypress, key
    end
  end

  def mouseclick(x, y)
    case x
    when 0
      @editor.handlekey "left", ""
      return true
    when self.w - 1
      @editor.handlekey "right", ""
      return true
    else
      @editor.cursor = getabscur(x - 1, @viewstart)
      return true
    end
  end
end

class JTTWEditpass < JTTWEditline
  def initialize(*params, &block)
    @displaytransformer = proc { |char| char ? ?*.ord : ?\s.ord }
    super
  end
end

class JTScroller
  # this is independent scrolling class, it maintain scrollbar state and can
  # draw a scrollbar on paintcontext and handle mouse action
  #
  # scrollbar model
  #
  #  +--+ 0.0 -+
  #  |  |      |startofview
  #  +==+ -----+
  #  |v |      |
  #  |i |      |
  #  |e |      |viewlength
  #  |w |      |
  #  +==+ -----+
  #  |  |
  #  |  |
  #  |  |
  #  +--+ 1.0
  #
  # The Scrollbar have basic range of 1.0, part of scrollbar is bar which
  # shows current portion of view. The bar start is at value startofview.
  # The bar length is value viewlength.
  #
  # All numbers shown above are multiplied by value scale.
  #
  attr_accessor :block
  attr_reader :scale
  include DelayedNotify

  def initialize(&block)
    # parameter is block to be notified when change occur
    delayednotify_init(&block)
    @stepwithview = true
    @scale = 1.0
    @startofview = 0.0
    @viewlength = 1.0
    @steplength = 1.0
  end

  def viewlength
    @viewlength * @scale
  end

  def viewlength=(v)
    v = 0.0 if v < 0.0
    v = @scale if v > @scale
    @viewlength = v / @scale; notify
  end

  def steplength
    @steplength * @scale
  end

  def steplength=(v)
    v = 0.0 if v < 0.0
    v = @scale if v > @scale
    @steplength = v / @scale; notify
  end

  def startofview
    @startofview * @scale
  end

  def startofview=(v)
    v /= @scale
    v = 0.0 if v < 0.0
    v = 1.0 - @viewlength if v > 1.0 - @viewlength
    @startofview = v; notify
  end

  def set_scale(v)
    # scale is changed, proportions are left
    @scale = v.to_f; notify
  end

  def set_lines(v)
    # scale is changed, scaled lengths are preserved
    delayednotify {
      absstartofview = self.startofview
      absviewlength = self.viewlength
      abssteplength = self.steplength
      @scale = v.to_f
      self.startofview = absstartofview
      self.viewlength = absviewlength
      self.steplength = abssteplength
    }
  end

  def setsteps(smallsteps, pagesteps, newscale)
    # set scrollbar to have desired count of smallsteps and
    # count of pages
    # absolute position is preserved if possible
    delayednotify {
      absstartofview = self.startofview
      @scale = newscale.to_f
      self.startofview = absstartofview
      @viewlength = 1.0 / (pagesteps + 1.0)
      @steplength = (1.0 - @viewlength) / smallsteps
    }
  end

  def normalizedposition
    # returns position of bar in 0.0 to scale range
    @scale * @startofview / (1.0 - @viewlength)
  end

  def normalizedposition=(v)
    # set position of bar in 0.0 to scale range
    @startofview = (v / @scale) * (1.0 - @viewlength)
    notify
  end

  def step_plus
    self.startofview += self.steplength
  end

  def step_minus
    self.startofview -= self.steplength
  end

  def view_plus
    self.startofview += self.viewlength
  end

  def view_minus
    self.startofview -= self.viewlength
  end

  def go_start
    @startofview = 0.0; notify
  end

  def go_end
    @startofview = 1.0 - @viewlength; notify
  end

  def drawat(pc, length, horizontal)
    # draw scrollbar at current positing in paint context pc
    # length is desired length of scrollbar
    # horizontal is false for vertical scrollbar
    length -= 2 # subtract size both side arrows
    startbardraw = (@startofview * (length - 1)).round
    endbardraw = ((@startofview + @viewlength) * (length - 1)).round
    barstarted = false
    pc.addchar(horizontal ? JTCur.acs_larrow : JTCur.acs_uarrow)
    length.times { |i|
      pc.moverel -1, 1 unless horizontal
      if i < startbardraw or (i > endbardraw and barstarted)
        pc.addchar(horizontal ? JTCur.acs_hline : JTCur.acs_vline)
      else
        barstarted = true
        pc.addchar JTCur.acs_ckboard
      end
    }
    pc.moverel -1, 1 unless horizontal
    pc.addchar(horizontal ? JTCur.acs_rarrow : JTCur.acs_darrow)
  end

  def mouseaction(pos, length)
    # decode and proceed mouse action
    # pos is relative position on scrollbar
    # length is length of scrollbar
    if pos == 0
      self.step_minus
    elsif pos == length - 1
      self.step_plus
    else
      pos -= 1; length -= 2
      startbardraw = (@startofview * length).round
      endbardraw = ((@startofview + @viewlength) * length).round
      if pos < startbardraw
        self.view_minus
      elsif pos >= endbardraw
        self.view_plus
      end
    end
  end
end

class JTTWScrollbox < JTTWFocusable
  attr_reader :scrollx, :scrolly, :virtualw, :virtualh

  def initialize(*params, &block)
    @virtualh = params.pop # last two parameters are virtual width and height
    @virtualw = params.pop
    @scrollx = nil
    @scrolly = nil
    @scrollhandler = proc { self.scrollcallback }
    super(*params, &block)
    updatescrollers
  end

  def virtualw=(v)
    @virtualw = v
    updatescrollers
  end

  def virtualh=(v)
    @virtualh = v
    updatescrollers
  end

  def virtualwh=(v)
    @virtualw = v[0]
    @virtualh = v[1]
    updatescrollers
  end

  def updatescrollers
    @scrollxsize = nil
    @scrollysize = nil
    @scrollxsize = self.w if @virtualw >= self.w
    @scrollysize = self.h if @virtualh >= self.h
    if @virtualw <= self.w and @virtualh <= self.h
      @scrollxsize = nil
      @scrollysize = nil
    end
    if @scrollxsize and @scrollysize
      @scrollxsize -= 1
      @scrollysize -= 1
    end
    @scrollxsize = 0 if @scrollxsize and @scrollxsize < 0
    @scrollysize = 0 if @scrollysize and @scrollysize < 0
    if @scrollxsize
      @scrollx = JTScroller.new(&@scrollhandler) unless @scrollx
      @scrollx.disablednotify { |sbar|
        sbar.set_lines(@virtualw.to_f)
        sbar.viewlength = @scrollxsize
        sbar.steplength = 1
      }
    else
      @scrollx = nil
    end
    if @scrollysize
      @scrolly = JTScroller.new(&@scrollhandler) unless @scrolly
      @scrolly.disablednotify { |sbar|
        sbar.set_lines(@virtualh.to_f)
        sbar.viewlength = @scrollysize
        sbar.steplength = 1
      }
    else
      @scrolly = nil
    end
    scrollcallback
  end

  def scrollcallback
    resizedclient
  end

  def computeclientarea
    ax = 0; ay = 0; aw = 0; ah = 0
    ax = -@scrollx.startofview.round if @scrollx
    ay = -@scrolly.startofview.round if @scrolly
    aw = @scrollxsize ? @scrollxsize - ax : self.w
    ah = @scrollysize ? @scrollysize - ay : self.h
    JTRectangle.new ax, ay, aw, ah
  end

  def paintself(pc)
    super
    pc.attrset @color_active if self.focused?
    if @scrolly
      pc.move self.w - 1, 0
      @scrolly.drawat pc, @scrollysize, false
    end
    if @scrollx
      pc.move 0, self.h - 1
      @scrollx.drawat pc, @scrollxsize, true
    end
  end

  def mouseclick(x, y)
    if @scrollx and y == self.h - 1 and x < @scrollxsize
      @scrollx.mouseaction x, @scrollxsize
    elsif @scrolly and x == self.w - 1 and y < @scrollysize
      @scrolly.mouseaction y, @scrollysize
    end
    action
  end

  def keypress(key)
    callupdate = true
    case key
    when "up", "C-p" then @scrolly.step_minus if @scrolly
    when "down", "C-n" then @scrolly.step_plus if @scrolly
    when "home", "M-<" then @scrolly.go_start if @scrolly
    when "end", "M->" then @scrolly.go_end if @scrolly
    when "pgup", "M-v" then @scrolly.view_minus if @scrolly
    when "pgdn", "C-v" then @scrolly.view_plus if @scrolly
    when "left", "C-b" then @scrollx.step_minus if @scrollx
    when "right", "C-f" then @scrollx.step_plus if @scrollx
    when "M-b" then @scrollx.view_minus if @scrollx
    when "M-f" then @scrollx.view_plus if @scrollx
    when "C-a" then @scrollx.go_start if @scrollx
    when "C-e" then @scrollx.go_end if @scrollx
    else
      callupdate = false
      addmessage @parent, :keypress, key
    end
    action if callupdate
  end

  def action
    @block.call self if @block
  end
end

class JTTWList < JTTWFocusable
  # this is abstract vertical list widget class
  # use its descendants or make own subclass with /list_.*/ methods overidden
  #
  attr_reader :focusedentry, :color_active, :color_basic

  def initialize(*params, &block)
    super(*params, &block)
    @scrollhandler = proc { self.scrollcallback }
    @focusedentry = 0     # index of focused entry
    @scrollx = nil
    @scrolly = nil
    @visiblerange = nil
    @linetoidx = nil
    @idxtoline = nil
    @color_active = JTTui.color_active
    @color_basic = JTTui.color_basic
    updatescrollers
  end

  def color_active=(v); @color_active = v; addmessage self, :paint; end
  def color_basic=(v); @color_basic = v; addmessage self, :paint; end

  def list_getitemsize(idx)
    # idx is index of item, may be out of range
    # return value should be nil or two element array
    # with width and height as elements
    raise "abstract method called"
  end

  def list_drawitem(pc, hilighted, focused, idx)
    # paintcontext pc is prepared and set to item coordinates and size
    # hilighted is boolean value, true for selected items
    # idx is index of item, may be out of range
    # large items should use pc.clippingrectangle to determine which parts
    #  needs to be redrawed
    # if item height is larger than area of whole window, rest wont be visible
    pc.attrset((hilighted && focused) ? @color_active : @color_basic)
    cx, cy, cw, ch = pc.clippingrectangle
    pc.fillrect cx, cy, cw, ch, ?\s.ord
    pc.move 0, 0
    pc.setcursor if hilighted
  end

  def list_gettotalwidth
    # should return length of widest item for horizontal scrollbar to work
    raise "abstract method called"
  end

  def list_getlength
    # should return last valid index+1, 0 for no item
    raise "abstract methos called"
  end

  def list_keyonitem(key, idx)
    # return true if key is handled false otherwise
    false
  end

  def list_mouseonitem(idx, relx, rely)
    # by default item is focused on mouse click
    self.focusedentry = idx
  end

  def scrollcallback
    addmessage self, :paint
  end

  def focusedentry=(v)
    @focusedentry = (0...self.list_getlength).clip v
    @focusedentry = 0 if @focusedentry < 0
    if @scrolly and (not @visiblerange or
                     not @visiblerange.include?(@focusedentry))
      @scrolly.normalizedposition = @focusedentry
    end
    addmessage self, :paint
  end

  def step_minus
    self.focusedentry -= 1
  end

  def step_plus
    self.focusedentry += 1
  end

  def go_start
    self.focusedentry = 0
  end

  def go_end
    self.focusedentry = self.list_getlength - 1
  end

  def view_minus
    idx = self.focusedentry
    hdiff = 0
    while hdiff < self.h - 1 and idx > 0
      itemsize = list_getitemsize(idx)
      hdiff += itemsize[1]
      idx -= 1
    end
    self.focusedentry = idx
  end

  def view_plus
    idx = self.focusedentry
    hdiff = 0
    while hdiff < self.h - 1 and idx < @virtualh
      itemsize = list_getitemsize(idx)
      hdiff += itemsize[1]
      idx += 1
    end
    self.focusedentry = idx
  end

  def updatescrollers
    @virtualw = list_gettotalwidth
    @virtualh = list_getlength
    @focusedentry = (0...@virtualh).clip @focusedentry
    @scrollxsize = nil
    @scrollysize = nil
    @scrollxsize = self.w if @virtualw >= self.w
    @scrollysize = self.h if @virtualh >= self.h
    if @virtualw <= self.w and @virtualh <= self.h
      @scrollxsize = nil
      @scrollysize = nil
    end
    if @scrollxsize and @scrollysize
      @scrollxsize -= 1
      @scrollysize -= 1
    end
    @scrollxsize = 0 if @scrollxsize and @scrollxsize < 0
    @scrollysize = 0 if @scrollysize and @scrollysize < 0
    if @scrollxsize
      @scrollx = JTScroller.new(&@scrollhandler) unless @scrollx
      @scrollx.disablednotify {
        @scrollx.set_scale(@virtualw.to_f)
        @scrollx.viewlength = @scrollxsize.to_f
        @scrollx.steplength = 1.0
      }
    else
      @scrollx = nil
    end
    if @scrollysize
      @scrolly = JTScroller.new(&@scrollhandler) unless @scrolly
      @scrolly.disablednotify {
        @scrolly.setsteps(@virtualh, @virtualh / @scrollysize, @virtualh)
      }
    else
      @scrolly = nil
    end
    addmessage self, :paint
  end

  def paintself(pc)
    super
    pc.attrset @color_active if self.focused?
    if @scrolly
      pc.move self.w - 1, 0
      @scrolly.drawat pc, @scrollysize, false
    end
    if @scrollx
      pc.move 0, self.h - 1
      @scrollx.drawat pc, @scrollxsize, true
    end
    pc.shrinkpaintarea(0, 0, 0, 0,
                       self.w - (@scrolly ? 1 : 0),
                       self.h - (@scrollx ? 1 : 0))
    idx = 0; yoffset = 0
    if @scrolly
      idx = @scrolly.normalizedposition.round
    end
    if @scrollx
      yoffset = @scrollx.startofview.round
    end
    hsum = 0
    startidx = idx
    @linetoidx = {}; @idxtoline = {}
    while hsum < self.h and idx < @virtualh
      itemsize = list_getitemsize(idx)
      break unless itemsize
      itemw, itemh = *itemsize
      pc.shrinkpaintarea(-yoffset, hsum,
                         0, 0, itemw, itemh) { |pcshrinked|
        list_drawitem(pcshrinked, @focusedentry == idx, self.focused?, idx)
      }
      itemh.times { |rh| @linetoidx[hsum + rh] = idx }
      @idxtoline[idx] = hsum
      idx += 1
      hsum += itemh
    end
    @visiblerange = startidx...(hsum >= self.h ? idx - 1 : idx)
  end

  def mouseclick(x, y)
    if @scrollx and y == self.h - 1 and x < @scrollxsize
      @scrollx.mouseaction x, @scrollxsize
    elsif @scrolly and x == self.w - 1 and y < @scrollysize
      @scrolly.mouseaction y, @scrollysize
    else
      if @linetoidx
        idx = @linetoidx[y]
        list_mouseonitem(idx, x, y - @idxtoline[idx]) if idx
      end
    end
  end

  def keypress(key)
    return false if list_keyonitem(key, @focusedentry)
    callupdate = true
    case key
    when "up", "C-p" then step_minus
    when "down", "C-n" then step_plus
    when "home", "M-<" then go_start
    when "end", "M->" then go_end
    when "pgup", "M-v" then view_minus
    when "pgdn", "C-v" then view_plus
    when "left", "C-b" then @scrollx.step_minus if @scrollx
    when "right", "C-f" then @scrollx.step_plus if @scrollx
    when "M-b" then @scrollx.view_minus if @scrollx
    when "M-f" then @scrollx.view_plus if @scrollx
    when "C-a" then @scrollx.go_start if @scrollx
    when "C-e" then @scrollx.go_end if @scrollx
    else
      callupdate = false
      addmessage @parent, :keypress, key
    end
    scrollaction if callupdate
  end

  def scrollaction
    # action on scrolling
  end

  def action
    @block.call self if @block
  end
end

class JTTWListLabels < JTTWList
  attr_accessor :list

  def initialize(*params, &block)
    @list = []
    @totalwidth = 1
    super
  end

  def update # call update after changing list size (vertical or horizontal)
    @totalwidth = 1
    @list.each_index { |idx|
      cw = self.list_getitemsize(idx)[0]
      @totalwidth = cw if cw > @totalwidth
    }
    updatescrollers
  end

  def list_getitemsize(idx)
    # idx is index of item, may be out of range
    # return value should be nil or two element array
    # with width and height as elements
    return nil if idx < 0
    return nil if idx >= @list.length
    itext = @list[idx]
    return 1, 1 unless itext
    itext = (itext + "\n").scan(/(.*)\n/).flatten
    ih = itext.length
    iw = 1
    iw = itext[0].length if itext[0]
    itext.each { |iline| iw = iline.length if iline.length > iw }
    return iw, ih
  end

  def list_drawitem(pc, hilighted, focused, idx)
    # cursor in paintcontext pc is at desired position
    # hilighted is boolean value, true for selected items
    # idx is index of item, may be out of range
    # large items should use pc.clippingrectangle to determine which parts
    #  needs to be redrawed
    # if item height is larger than area of whole window, rest wont be visible
    super
    return nil if idx < 0
    return nil if idx >= @list.length
    itext = @list[idx]
    itext = itext.split("\n")
    linenum = 0
    itext.each { |iline| pc.addstr iline; linenum += 1; pc.move(0, linenum) }
  end

  def list_gettotalwidth
    # should return length of widest item for horizontal scrollbar to work
    @totalwidth
  end

  def list_getlength
    # should return last valid index+1, 0 for no item
    @list.length
  end
end

class JTTWListButtons < JTTWList
  attr_accessor :list

  def initialize(*params, &block)
    @list = []
    super
  end

  def update # call update after changing list
    updatescrollers
  end

  def list_keyonitem(key, idx)
    # return true if key is handled false otherwise
    case key
    when "C-m", "C-j", " "
      self.focusedentry = idx
      action
    else
      return false
    end
    true
  end

  def list_mouseonitem(idx, relx, rely)
    # by default item is focused on mouse click
    self.focusedentry = idx
    action
  end

  def list_getitemsize(idx)
    # idx is index of item, may be out of range
    # return value should be nil or two element array
    # with width and height as elements
    return nil if idx < 0
    return nil if idx >= @list.length
    return self.w - 1, 1
  end

  def list_drawitem(pc, hilighted, focused, idx)
    # cursor in paintcontext pc is at desired position
    # hilighted is boolean value, true for selected items
    # idx is index of item, may be out of range
    # large items should use pc.clippingrectangle to determine which parts
    #  needs to be redrawed
    # if item height is larger than area of whole window, rest wont be visible
    super
    return nil if idx < 0
    return nil if idx >= @list.length
    itext = @list[idx]
    s = "[" + itext.center(self.w - 3) + "]"
    pc.addlabelstr s, (hilighted && focused),
      @color, @color_active, @color_hi, @color_active_hi
    pc.move 1, 0
  end

  def list_gettotalwidth
    # should return length of widest item for horizontal scrollbar to work
    self.w - 1
  end

  def list_getlength
    # should return last valid index+1, 0 for no item
    @list.length
  end

  def action
    # call with self and button number
    @block.call(self, @focusedentry) if @block
  end
end

class JTTWListCheckboxes < JTTWList
  attr_accessor :list, :states, :thirdstate

  def initialize(*params, &block)
    @list = []
    @states = []
    @thirdstate = false
    # elements of @states are 0, 1 ( or 2 for third state)
    # warning: it is responsibility of code that change size of @list
    #          to change @states also to be same size
    super
  end

  def update # call update after changing list
    if @list.length != @states.length
      raise "states and list properties are not synchronized"
    end
    updatescrollers
  end

  def changestate(idx)
    s = @states[idx]
    if @thirdstate
      s = (s + 1) % 3
    else
      s = (s + 1) % 2
    end
    @states[idx] = s
  end

  def list_keyonitem(key, idx)
    # return true if key is handled false otherwise
    case key
    when "C-m", "C-j", " "
      self.focusedentry = idx
      changestate idx
      action
    else
      return false
    end
    true
  end

  def list_mouseonitem(idx, relx, rely)
    # by default item is focused on mouse click
    self.focusedentry = idx
    changestate idx
    action
  end

  def list_getitemsize(idx)
    # idx is index of item, may be out of range
    # return value should be nil or two element array
    # with width and height as elements
    return nil if idx < 0
    return nil if idx >= @list.length
    return self.w - 1, 1
  end

  def list_drawitem(pc, hilighted, focused, idx)
    # cursor in paintcontext pc is at desired position
    # hilighted is boolean value, true for selected items
    # idx is index of item, may be out of range
    # large items should use pc.clippingrectangle to determine which parts
    #  needs to be redrawed
    # if item height is larger than area of whole window, rest wont be visible
    super
    return nil if idx < 0
    return nil if idx >= @list.length
    itext = @list[idx]
    istate = @states[idx]
    s = "[" + (" x?"[istate]).chr + "] " + itext
    pc.addlabelstr s, (hilighted && focused),
      @color, @color_active, @color_hi, @color_active_hi
    pc.move 1, 0
  end

  def list_gettotalwidth
    # should return length of widest item for horizontal scrollbar to work
    self.w - 1
  end

  def list_getlength
    # should return last valid index+1, 0 for no item
    @list.length
  end

  def action
    # call with self and button number
    @block.call(self, @focusedentry) if @block
  end
end

class JTTreeNode
  include Observable
  include DelayedNotify
  attr_reader :datalink, :parent, :subnodes

  def initialize(parent, datalink)
    @parent = parent
    @datalink = datalink
    @subnodes = []
    @parent.add_child self if @parent
    if @parent
      @root = @parent.getroot
    else
      @root = self
      delayednotify_init { changed; notify_observers }
    end
  end

  def notifyroot
    @root.notify
  end

  def delayednotifyroot(&block)
    @root.delayednotify &block
  end

  def datalink=(v)
    @datalink = v
    notifyroot
  end

  def remove
    delayednotifyroot {
      @subnodes.dup.each { |node| node.remove }
    }
    @parent.del_child self if @parent
    @datalink = nil
  end

  def add_child(c)
    @subnodes << c
    notifyroot
  end

  def del_child(c)
    @subnodes.delete c
    notifyroot
  end

  def getroot
    @root
  end

  def leaf?
    @subnodes.length == 0
  end

  def lastnode?
    parent.subnodes.last == self
  end
end

class JTTWTreeNode < JTTreeNode
  attr_reader :expand
  # expand set to false (default) means that sub-nodes will not be drawn
  def initialize(*params, &block)
    @expand = false
    super
  end

  def expand=(v)
    @expand = node_isexpandable? ? v : false
    if @expand
      node_tryexpand
    else
      node_collapse
    end
    notifyroot
  end

  def node_getsize
    # node should return size in [width,height] format (this does not include
    # control elements of node)
    raise "abstract method called"
  end

  def node_draw(pc, hilighted, focused)
    # node should draw self acording to flags
  end

  def node_isexpandable?
    # if true, node is drawn as collapsed but expandable
    # on try to expand node, node_tryexpand is called
    # this should be used for very large trees such as file systems
    # to allow expansion of directories only where necessary.
    # see node_collapse also
    not self.leaf?
  end

  def node_tryexpand
    # user try to expand 'expandable' node
    # new nodes should be added if ok
  end

  def node_collapse
    # for large trees it may be good to free subnodes when they are not visible
    # this is place for doing this
  end

  def node_key(key)
    # return true if key is handled false otherwise
    false
  end

  def node_mouse(relx, rely)
    # the item is focused on mouse click elsewhere
  end
end

class JTTWTree < JTTWList
  attr_reader :rootnode

  def initialize(*params, &block)
    @totalwidth = 1
    @rootnode = JTTWTreeNode.new(nil, nil) unless @rootnode
    # @rootnode may be set from descendant before calling super
    @rootnode.add_observer self
    @idxtonode = []
    @idxtoindent = []
    @nodetoidx = {}
    super
  end

  def rootnode=(newroot)
    @rootnode.delete_observer self
    @rootnode = newroot
    update
  end

  def update
    @totalwidth = 1 # updated in fillidxtonodelist
    @totalheight = 0
    @idxtonode = []
    @idxtoindent = []
    @nodetoidx = {}
    fillidxtonodelist(@rootnode, " ")
    @totalwidth += 1
    updatescrollers
  end

  def fillidxtonodelist(node, indentstr)
    node.subnodes.each { |subnode|
      nw, nh = subnode.node_getsize
      sign = "?"
      if subnode.leaf?
        sign = ((node.subnodes.last == subnode) ?
          "\15" :
          "\17")
      end
      sign = "+" if subnode.node_isexpandable?
      sign = "-" if subnode.expand
      @nodetoidx[subnode] = @idxtonode.length
      @idxtonode << subnode
      currentindentstr = (indentstr[-1] == "\37" ?
        indentstr[0..-1] + "\17" + sign :
        indentstr + sign)
      @idxtoindent << currentindentstr
      @totalheight += nh
      indentpos = indentstr.length
      @totalwidth = indentpos + nw if @totalwidth < indentpos + nw
      if subnode.expand
        subsign = (subnode.lastnode? ? " " : "\37")
        fillidxtonodelist(subnode,
                          indentstr + subsign)
      end
    }
  end

  def select_node(node)
    idx = @nodetoidx[node]
    idx = 0 unless idx
    self.focusedentry = idx
  end

  def list_getitemsize(idx)
    # idx is index of item, may be out of range
    # return value should be nil or two element array
    # with width and height as elements
    return nil if idx < 0
    return nil if idx >= @idxtonode.length
    node = @idxtonode[idx]
    return 1, 1 unless node
    nw, nh = node.node_getsize
    nw += @idxtoindent[idx].length
    return nw, nh
  end

  def list_drawitem(pc, hilighted, focused, idx)
    # cursor in paintcontext pc is at desired position
    # hilighted is boolean value, true for selected items
    # idx is index of item, may be out of range
    # large items should use pc.clippingrectangle to determine which parts
    #  needs to be redrawed
    # if item height is larger than area of whole window, rest wont be visible
    super
    return nil if idx < 0
    return nil if idx >= @idxtonode.length
    node = @idxtonode[idx]
    if node
      indentstr = @idxtoindent[idx]
      indentstrmore = indentstr[0..-2] + (node.lastnode? ? " " : "\37")
      indentstr = ">" + indentstr[1..-1] if hilighted
      nodew, nodeh = node.node_getsize
      nodeh.times { |line|
        pc.move 0, line
        pc.addstr(line > 0 ? indentstrmore : indentstr)
      }
      il = indentstr.length
      pc.shrinkpaintarea(il, 0,
                         0, 0, nodew, nodeh) { |pcshrinked|
        node.node_draw(pcshrinked, hilighted, focused)
      }
    end
  end

  def list_gettotalwidth
    # should return length of widest item for horizontal scrollbar to work
    @totalwidth
  end

  def list_getlength
    # should return last valid index+1, 0 for no item
    @idxtonode.length
  end

  def list_keyonitem(key, idx)
    # return true if key is handled false otherwise
    node = @idxtonode[idx]
    node.node_key(key) if node
  end

  def list_mouseonitem(idx, relx, rely)
    # the item is focused on mouse click elsewhere
    # FIXME: correct relx and rely to real relative position
    @idxtonode[idx].node_mouse(relx, rely)
    self.focusedentry = idx
  end
end

class JTTWTreeNodeLabel < JTTWTreeNode
  attr_reader :label

  def initialize(*params, &block)
    @label = params.pop
    super(*params, &block)
  end

  def label=(str)
    @label = str
    notifyroot
  end

  def node_getsize
    # node should return size in [width,height] format (this does not include
    # control elements of node)
    nodetext = (@label + "\n").scan(/(.*)\n/).flatten
    nh = nodetext.length
    nw = 1
    nw = nodetext[0].length if nodetext[0]
    nodetext.each { |nodeline| nw = nodeline.length if nodeline.length > nw }
    return nw, nh
  end

  def node_draw(pc, hilighted, focused)
    # node should draw self acording to flags
    super
    nodetext = @label.split("\n")
    linenum = 0
    nodetext.each { |nodeline|
      pc.addstr nodeline
      linenum += 1
      pc.move(0, linenum)
    }
  end

  def node_key(key)
    return true if super
    case key
    when "C-m", "C-j"
      self.expand ^= true
    else
      return false
    end
    true
  end
end

class JTTWTreeNodeCheckbox < JTTWTreeNode
  attr_reader :label, :state, :states, :statesstring

  def initialize(*params, &block)
    @label = params.pop
    @state = 0
    @states = 2
    @statesstring = " x?"
    @block = block
    super(*params)
  end

  def label=(str)
    @label = str
    notifyroot
  end

  def state=(v)
    @state = v
    notifyroot
  end

  def states=(v)
    @states = v
    if @state >= @states
      @state = 0
      notifyroot
    end
  end

  def statesstring=(v)
    @statesstring = v
    notifyroot
  end

  def node_getsize
    # node should return size in [width,height] format (this does not include
    # control elements of node)
    nodetext = (@label + "\n").scan(/(.*)\n/).flatten
    nh = nodetext.length
    nw = 1
    nw = nodetext[0].length + 4 if nodetext[0]  # +4 place for is for checkbox
    nodetext.each { |nodeline| nw = nodeline.length if nodeline.length > nw }
    return nw, nh
  end

  def node_draw(pc, hilighted, focused)
    # node should draw self acording to flags
    super
    nodetext = @label.split("\n")
    linenum = 0
    nodetext.each { |nodeline|
      pc.addstr "[#{@statesstring[@state].chr}] " if linenum == 0
      pc.addstr nodeline
      linenum += 1
      pc.move(0, linenum)
    }
  end

  def node_key(key)
    return true if super
    case key
    when "C-m", "C-j"
      self.expand ^= true
    when " ", "ins"
      action
    else
      return false
    end
    true
  end

  def action
    delayednotifyroot {
      self.state = (@state + 1) % @states
      @block.call self if @block
    }
  end

  def node_mouse(relx, rely)
    action
  end
end

class JTTWScrollbar < JTTWFocusable
  attr_reader :scroller

  def initialize(*params, &block)
    @horizontal = params.pop # last parameter is horizontal/vertical selector
    @scroller = JTScroller.new { self.scrollcallback }
    super(*params, &block)
  end

  def scrollcallback
    addmessage self, :paint
  end

  def paintself(pc)
    super
    pc.attrset @color_active if self.focused?
    pc.move 0, 0
    @scroller.drawat pc, (@horizontal ? self.w : self.h), @horizontal
  end

  def mouseclick(x, y)
    @scroller.mouseaction(@horizontal ? x : y, @horizontal ? self.w : self.h)
    action
  end

  def keypress(key)
    callupdate = true
    if @horizontal
      case key
      when "left", "C-b" then @scroller.step_minus
      when "right", "C-f" then @scroller.step_plus
      when "M-b" then @scroller.view_minus
      when "M-f" then @scroller.view_plus
      when "C-a" then @scroller.go_start
      when "C-e" then @scroller.go_end
      else
        callupdate = false
        addmessage @parent, :keypress, key
      end
    else
      case key
      when "up", "C-n" then @scroller.step_minus
      when "down", "C-p" then @scroller.step_plus
      when "home", "M-<" then @scroller.go_start
      when "end", "M->" then @scroller.go_end
      when "pgup", "C-v" then @scroller.view_minus
      when "pgdn", "M-v" then @scroller.view_plus
      else
        callupdate = false
        addmessage @parent, :keypress, key
      end
    end
    action if callupdate
  end

  def action
    @block.call self if @block
  end
end

class JTTWGrid < JTTWidget
  def setcontent(xspacing, yspacing, *aryary)
    # usage
    # g.setcontent(1,1,
    #              [but11,but12,but13],
    #              [but21,but22,but23],
    #              [but31,but32,but33])
    # this 2D array must be rectangular
    # elements must be JTTWFocusable compatible
    @aryary = aryary
    @rowcount = @aryary.length
    @colcount = @aryary[0].length
    @aryary.each { |row|
      row.each { |w|
        @parentdialog.addtabstop w if w
      }
    }
    rowsizes = []; colsizes = [0] * @colcount
    @aryary.each { |row|
      rowsizes << (row.collect { |w| w.h }).max
    }
    colsizes = @aryary.foldr(colsizes) { |r1, r2w|
      maximal = []
      (0...r1.length).each { |i|
        maximal << (r1[i].w < r2w[i] ? r2w[i] : r1[i].w)
      }
      maximal
    }
    cury = 0
    @aryary.each_with_index { |row, rowidx|
      curx = 0
      row.each_with_index { |w, colidx|
        w.x = curx; w.y = cury
        curx += colsizes[colidx] + xspacing
      }
      cury += rowsizes[rowidx] + yspacing
    }
  end

  def getpos
    x = nil; y = nil
    @aryary.each_with_index { |row, rowidx|
      row.each_with_index { |w, colidx|
        if w.focused?
          y = rowidx
          x = colidx
        end
      }
    }
    return x, y
  end

  def settabxy(x, y)
    if x >= 0 and y >= 0 and @aryary[y] and @aryary[y][x]
      @parent.settab @aryary[y][x]
      true
    else
      false
    end
  end

  def keypress(key)
    unless case key
    when "C-n", "down" then x, y = getpos; settabxy(x, y + 1)
    when "C-f", "right" then x, y = getpos; settabxy(x + 1, y)
    when "C-p", "up" then x, y = getpos; settabxy(x, y - 1)
    when "C-b", "left" then x, y = getpos; settabxy(x - 1, y)
    else
      false
    end
      addmessage @parent, :keypress, key
    end
  end
end

class JTTWMessagebox
  # this class creates modal dialog window with text and array of buttons
  # button of number defaultnr is preselected, the button of number cancelnr is
  # pressed by 'esc' key too
  # usage: m=JTTWMessagebox.new('Press one of buttons',0,1,'Butt1','Butt2')
  #        a=m.execute
  #        b=m.execute 'Now press the first' # temporary text change
  #        ...
  # if cancelnr is nil, no action occur on 'esc' key
  # if cancelnr is -1, cancel will end dialog with result=-1
  # minwidth member specifies minimal width of messagebox, if you want long
  # lines in label set this to bigger value (10 is low limit)
  attr_accessor :text, :buttons, :cancelnr, :defaultnr
  attr_reader :minwidth

  def initialize(text, defaultnr, cancelnr, *buttons)
    @text = text
    @cancelnr = cancelnr
    @defaultnr = defaultnr
    @buttons = buttons
    @result = nil
    @minwidth = 30 # this is nice looking value
    # nil=not yet, number in range 0...buttons.length is position of button
  end

  def minwidth=(v)
    if v >= 10 # 10 is minimal usable size
      @minwidth = v
    else
      raise "minimal message box window size must be 10 or more"
    end
  end

  def execute(thetext = @text)
    @result = -1
    mesdlg = JTTDialog.new(JTTui.rootwindow, "Messagebox Window " + object_id.to_s,
                           0, 0, 0, 0, "")
    mesdlg.align = JTTWindow::ALIGN_CENTER
    mesdlg.up
    wsize = 1 # compute width of array of buttons
    realbuttons = []
    @buttons.each_with_index { |bname, index|
      bwsize = JTWHilightletter.hl_countchars(bname) + 4
      realbuttons << JTTWButton.new(mesdlg, "Messagebox Button",
                                    wsize, 0, bwsize, 1, bname) {
        @result = index
        mesdlg.addmessage nil, :quitloop
      }
      wsize += bwsize + 1
    }
    wsize += 2
    wsize = [wsize, @minwidth].max
    label = JTTWLabel.new(mesdlg, "Messagebox Label " + object_id.to_s,
                          1, 1, wsize - 4, 1, thetext)
    hlsize = [label.breaklines.length, mesdlg.parent.h - 5].min
    label.h = hlsize
    hsize = hlsize + 5
    realbuttons.each { |b| b.y = hsize - 3 }
    mesdlg.h = hsize
    mesdlg.w = wsize
    mesdlg.addmessage mesdlg, :paint
    realbuttons.each { |b| mesdlg.addtabstop b }
    if @cancelnr == -1
      def mesdlg.keypress(k)
        if k == "esc"
          JTTui.addmessage nil, :quitloop
        else
          super
        end
      end
    elsif @cancelnr # if not nil
      mesdlg.cancelbutton = realbuttons[@cancelnr]
    end
    mesdlg.settab realbuttons[@defaultnr]
    JTTui.messageloop
    mesdlg.close
    @result
  end
end
