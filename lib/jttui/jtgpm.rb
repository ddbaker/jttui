#
# Jakub Travnik's textmode user interface
# jtgpm.rb - gpm mouse reader, part of jttui
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

# Note:
#  this program requires gpm socket at /dev/gpmctl to work, otherwise
#  jttui will use xterm sequences


begin
$NOSOCKET=false
require 'socket'
rescue LoadError
$NOSOCKET=true
end

module JTGPMouse
  extend self
  # event numbers
  MEvent_move=1
  MEvent_drag=2
  MEvent_down=4
  MEvent_up=8
  MEveny_single=16
  MEvent_double=32
  MEvent_triple=64
  MEvent_mflag=128
  # there are other events but we won't use them
  # Event_mask is default eventmask for this module
  Event_mask=MEvent_down+MEvent_up+MEveny_single+
    MEvent_double+MEvent_mflag
  # no default handler even for drag and triple clicks
  Default_mask= ~ (Event_mask | MEvent_drag | MEvent_triple)
  # button numbers
  MButton_left=4
  MButton_middle=2
  MButton_right=1
  # margin numbers
  MMargin_top=1
  MMargin_bottom=2
  MMargin_left=4
  MMargin_right=8
  # init mouse returns false if gpm is not communicating
  def init_mouse(evmask=Event_mask, defaultmask= Default_mask,
		 minmod=0, maxmod=0)
    return false if $NOSOCKET
    @gpmsock=nil
    tn=ttynumber
    @gpmsock=UNIXSocket.open('/dev/gpmctl')
    request=[evmask, defaultmask, minmod, maxmod, $$, tn].pack 'S4i2'
    @gpmsock.write request
    @gpmsock.flush
    true
  rescue
    @gpmsock.close if @gpmsock
    @gpmsock=false
  end
  def close_mouse
    @gpmsock.close if @gpmsock
  end
  def ok?; @gpmsock ? true : false end
  def event?
    return false unless @gpmsock
    (select [@gpmsock],nil,nil,0) ? true : false
  end
  def readevent
    reply=@gpmsock.read 24
    @gpmb,@modifiers,@vc,@dx,@dy,@x,@y,@etype,@clicks,@margin=
      reply.unpack 'C2Ss4i3'
    @x-=1;@y-=1 # we want top left corner to be 0,0
    @button=1 if @gpmb & MButton_left !=0     # xterm mouse like buttons
    @button=2 if @gpmb & MButton_middle !=0
    @button=3 if @gpmb & MButton_right !=0
    @button=4 if @etype & MEvent_up !=0
    return @button,@x,@y
  end
  def ttynumber
    tty=JTCur.ttyname $stdin.fileno
    raise 'not a tty' unless tty
    r=tty.scan(/(\d\d?\d?)\Z/)
    # gpm mouse now works even when consoles does not contain
    # 'tty' substring in name (such as '/dev/vc/1'). Original libgpm
    # library (which we bypass and comunicate with gpm server directly)
    # itself have problem with this (you can try for example with
    # Midnight Commander aka mc).
    # But we need to determine if we are running on the linux console
    # or in some xterminal that does not work with gpm:
    # following regexp try to guess if we are on console, otherwise
    # raise exception to disable gpm processing (and use xterm mouse
    # escape sequences through jtkey.rb)
    raise 'not a linux console tty' if tty !~ /(\/vc\/|\/tty\d|\/console)/
    raise 'tty name does not end with number' if r==[]
    r[0][0].to_i
  end
  attr_reader :button,:gpmsock,:gpmb,:modifiers,
    :vc,:dx,:dy,:x,:y,:etype,:clicks,:margin
end

