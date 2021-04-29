# -*- coding: utf-8 -*-
#
# jtkey.rb - terminal keys reader, part of jttui
# classes for dealing with keys and xterm mouse or gpm (in jtgpm.rb)
#
# This file is distributed under this license:
# Jakub Travnik's textmode user interface (JTTui) is copyrighted free software
# by Jakub Travnik 
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

# note: terminal specific files are loaded first from ~/.jtkey/TERM.$TERM
# or if above file does not exist, from /usr/lib/jtkey/TERM.$TERM
# where $TERM is environment variable
# if none of above is found, key learning will start at JTKey.init_key
#
# key learning may be forced by running: JTKey.init_key true

require "jttui/jtutil"
require "jttui/jtgpm"

module JTKey
  extend self

  # keynames is not all, other keys are encoded as their ascii code
  # i.e. "a" "A" or meta(alt) keys prefixed with "M-" i.e. "M-a"
  # control-key is left verbatim i.e. control-a is "\001" == ?\C-a.chr
  # function keys may be pressed as ESC+number and have names "f1" .. "f10"
  # double escape is "esc" (not "M-\e")
  # note: "EOF" is returned for end of file state on $stdin
  #       this is possible by C-d when terminal is in non-raw mode
  @keynames = %w{left right up down ins del home end pgup pgdn
                 f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12}

  # test if keys are pending
  # return nil if input queue is empty
  def keypressed?
    (select([$stdin], nil, nil, 0) or JTGPMouse.event?) ? true : false
  end

  # readkey return key name as String or array of mouse status
  # key names are strings defined in keynames array
  # one character strings denote ascii value of key
  # multi character are names of key such a 'left'
  # [b,x,y] is returned for mouse where
  #        b is button 1=left 2=middle 3=right 4=depress of button
  #        x,y are coordinates i.e. 'mouse 1,0,0' left button pressed at 0,0
  # '' is returned in nonblocking mode if no key is pending and timeout expired
  # nonblocking mode is for nil or none parameter, otherwise expected
  # Float or Fixnum value means timeout in seconds
  def readkeynb; readkey(0.0) end

  def readkey(blocktime = nil)
    return @outputkeybuff.shift if @outputkeybuff.length > 0
    while blocktime != 0 or keypressed? or JTGPMouse.event?
      sel = @mouseisgpm ? [$stdin, JTGPMouse.gpmsock] : [$stdin]
      selres = select(sel, [], [], blocktime)
      return "" unless selres
      if selres[0].include? JTGPMouse.gpmsock
        mouse = JTGPMouse.readevent
        return [mouse[0], mouse[1], mouse[2]]
      end
      c = $stdin.getc # nil may be returned
      return "EOF" unless c
      @inputkeybuff << c.chr
      # identify characters in input buffer
      keyname = @keyhash[@inputkeybuff]
      if keyname # if key is known, return it and clear buffer
        @inputkeybuff = ""
        return keyname
      end
      if @inputkeybuff.prefix? "\e[M" # xterm mouse
        if @inputkeybuff.length >= 6 # complete
          b = @inputkeybuff[3].force_encoding("ASCII-8BIT").ord - 31
          x = @inputkeybuff[4].force_encoding("ASCII-8BIT").ord - 33
          y = @inputkeybuff[5].force_encoding("ASCII-8BIT").ord - 33
          @inputkeybuff = ""
          return [b, x, y]
        end
        # incomplete xterm mouse sequence
        next
      end
      # input buffer contain incomplete or unknown key
      # count all keys that have buffer as prefix
      count = 0
      @keyhash.each_key { |x|
        if x.prefix? @inputkeybuff
          count += 1
          break # count== 0 or 1 is enough information so quit loop
        end
      }
      # if count is zero, buffer contain unknown key
      # it will be sent by characters
      if count == 0
        @inputkeybuff.each_byte { |x| @outputkeybuff << x.chr }
        @inputkeybuff = ""
        return @outputkeybuff.shift
      end
      # otherwise read next character to complete key
    end
    # nonblocking exit without key found yet
    return ""
  end

  def learnkeys
    print "Learn keys for #{ENV["TERM"]} terminal:\n" +
            "press requested key then enter for every entry" +
            "(or press enter to ingnore key)\n"
    @keyhash = Hash.new
    @keynames.each { |x| print x, ": "; @keyhash[gets.chomp] = x }
    print "note: f1-f10 keys will be also accessible as ESC digit\n"
    print "Adding standard keys ...\n"
    @keyhash[0.chr] = "C-@" # on some keyboards this is C-SPC or C-`
    (1..26).each { |x| @keyhash[x.chr] = "C-" + (x + ?a.ord - 1).chr }
    # control keys i.e.'C-x'
    #27 is esc
    @keyhash[28.chr] = 'C-\\' # signals bust be turned of for this (raw mode)
    @keyhash[29.chr] = "C-]"
    @keyhash[30.chr] = "C-^"
    @keyhash[31.chr] = "C-_"
    (32..255).each { |x| @keyhash[x.chr] = x.chr } # these keys are not translated
    @keyhash[127.chr] = "backspace"
    (1..9).each { |x| @keyhash["\e" + x.to_s] = "f" + x.to_s } # ESC+num to fnum
    @keyhash["\e0"] = "f10"
    # add meta keys that are not in conflict with already defined keys
    (0..255).each do |x|
      mk = "\e" + x.chr # metakey codes
      @keyhash[mk] = "M-" + @keyhash[x.chr] unless (@keyhash.detect { |k, v|
        k.prefix? mk
      } or x == 27)
    end
    @keyhash["\e\e"] = "esc"
    @keyhash.delete "" # empty string (from ignored keys) not wanted
    storepath = ENV["HOME"] + "/.jtkey/"
    storefile = "TERM." + ENV["TERM"]
    begin
      print "By default terminal information are stored in $HOME/.jtkey/" +
              " directory. You can\ncopy them into /usr/lib/jtkey/ so all users can" +
              " share them.\nSearch order is: home directory first.\n"
      print "Warning! Following path contains upper directory references. " +
              "Check it carefully.\n" if (storepath + storefile) =~ /\.\./
      print "Store keys in '#{storepath + storefile}' ? [y/n]: "
      $stdout.flush
      yn = gets
    end until yn =~ /^(y|n)$/i
    storekeydef(storepath, storefile) if yn =~ /y/i
    update
    GC.start
  end

  def loadkeydef(filename)
    hashes = []
    File.open(filename) { |f| hashes = Marshal.load(f) }
    @keyhash = hashes[0]
    @inversekeyhash = hashes[1]
    update
  end

  def storekeydef(path, filename)
    Dir.mkdir(path) unless begin
      st = File.stat path
      st.directory?
    rescue
      false
    end
    @inversekeyhash = {}
    @keyhash.each_pair { |k, v| @inversekeyhash[v] = k }
    File.open(path + filename, "w+") { |f|
      Marshal.dump([@keyhash, @inversekeyhash], f)
    }
  rescue
    print "Warning! Cannot store keys in #{path + filename}\n"
    sleep 4
  end

  def init_key(learn = false)
    @inputkeybuff = ""  # characters read from terminal
    @outputkeybuff = [] # array of translated key names
    if learn
      learnkeys
    else
      term = ENV["TERM"]
      lpath = ENV["HOME"] + "/.jtkey/TERM." + term
      lpath = "/usr/lib/jtkey/TERM." + term unless File.exist? lpath
      if File.exist? lpath
        loadkeydef(lpath)
      else
        print "You are using terminal #{term} which is not in database\n"
        learnkeys
      end
    end
    # try to enable xterm mouse if gpm don't work
    # note: xterm mouse reports only mouse clicks,
    #       not movement (jtgpm does same by default, but is more capable)
    @mouseisgpm = JTGPMouse.init_mouse
    print "\e[?1000h" unless @mouseisgpm
  end

  def reenablemouse # after resize (i.e. for gnome-terminal)
    print "\e[?1000h" unless @mouseisgpm
  end

  def close_key
    if @mouseisgpm
      JTGPMouse.close_mouse
    else
      print "\e[?1000l" # disable xterm mouse
    end
  end

  # update of @keyhash
  def update
    # not used yet
  end

  def inverselookup(cookedkey)
    return "\e" if "\e" == cookedkey
    @inversekeyhash[cookedkey]
  end
end
