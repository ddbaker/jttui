#
# Jakub Travnik's utility functions, used by jttui and jc file commander
#
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


# Utilities:
#
# enlarge String class with prefix? and suffix? tests
# I would like these to be in standard library
#
# str.prefix?(parameter)-> false if parameter is not prefix of str
# str.suffix?(parameter)-> false if parameter is not suffix of str
# non false value otherwise
#
class String
  def prefix?(p)
    index(p)==0
  end
  def suffix?(s)
    part=self[-s.length..-1]
    part == s or s.length == 0
  end
end

#
# reraising exception with updated caller
def reraise
  raise $!.class, $!.message, caller[1..-1]
end

#
# clipping values into given numeric range
#
# note: return value is invalid for inversed ranges
class Range
  def clip(value)
    return self.begin if value < self.begin
    if exclude_end?
      return self.end-1 if value >= self.end
    else
      return self.end  if value > self.end
    end
    value
			# btw: methods begin and end break formating in emacs
  end
end

class Array
  # foldr and foldl applies function (block) to pair generated from
  # array element and previous value, the first previous value is parameter

  # I would like these to be in standard library
  # they allow many uses, consider these
  # sum=ary.foldr(0){|a,b| a+b}
  # product=ary.foldr(1){|a,b| a*b}
  # object_of_minimal_value=ary.foldr(ary.last){|a,b| a.value<b.value ? a : b}
  # object_of_maximal_value=ary.foldr(ary.last){|a,b| a.value>b.value ? a : b}
  # lisp_like_list=ary.foldr(nil){|a,b| [a,b]}
  # reversed_lisp_like_list=ary.foldl(nil){|a,b| [a,b]}
  # and so on ... :-)
  # yes, they are not fast, but I would use C if I want speed

  # foldr start from right: [1,2,3].foldr(4) &f => f(1,f(2,f(3,4)))
  def foldr(right,&block)
    self.reverse_each{|elt| right=block.call(elt,right)}
    right
  end
  # foldl start from left: [1,2,3].foldr(0) &f => f(f(f(0,1),2),3)
  def foldl(left,&block)
    self.each{|elt| left=block.call(left,elt)}
    left
  end
end


module DelayedNotify
  # This common pattern found in jttuistd.rb
  # When is it useful?
  #  You want setter methods to update something (in case of jttuistd.rb
  #  usually update is repainting). It is nice when it works automatically, but
  #  this may cause slow down. Delayed notify allows to delay update where
  #  necessary.
  #
  # class AverageOfTwo
  #   attr_reader :valueone, :valuetwo, :average
  #   include DelayedNotify
  #   def initialize(v1,v2)
  #     @valueone=v1; @valuetwo=v2
  #     delayednotify_init { @average=(@valueone+@valuetwo)/2.0 }
  #     notify
  #   end
  #   def valueone=(v); @valueone=v; notify; end
  #   def valuetwo=(v); @valuetwo=v; notify; end
  # end
  # aot=AverageOfTwo.new(1,3)
  # p aot.average
  # aot.valueone=6
  # p aot.average
  # aot.delayednotify {
  #   aot.valueone=20  # no update here
  #   aot.valuetwo=10  # no update here
  # }     # <-- update occur here
  # p aot.average
  #
  def delayednotify_init(&block)
    # set update block
    @delayednotify_blocked=0
    @delayednotify_block=block
  end
  def notify
    # notify update method unless blocked
    if @delayednotify_blocked == 0
      @delayednotify_block.call(self) if @delayednotify_block
    end
  end
  def delayednotify(&block)
    # run block with disabled update, then enable update and notify
    @delayednotify_blocked+=1
    yield(self)
  ensure
    @delayednotify_blocked-=1
    notify
  end
  def disablednotify(&block)
    # run block with disabled update, then enable update without notify
    @delayednotify_blocked+=1
    yield(self)
  ensure
    @delayednotify_blocked-=1
  end
end


# DEBUGING SUPPORT
# change output file or device as you wish,
# I prefer debug.log file or /dev/tty3 (on tty1 emacs, on tty2 tested program)
#
def debug_output_file
  'debug.log'
end
  
def debug(*p)
  File.open(debug_output_file,"a") do |f|
    f.write caller[2]+"=>> " # there is [0]=open [1]=debug [2]=real caller
    p.each_index{ |i|
      f.write ", " if i>0
      f.write p[i].inspect
    }
    f.write "\r\n" # \r\n" # adjust as you need
    f.flush
  end
end

debug 'NEW DEBUG SESSION', Time.now.to_s if test(?e,debug_output_file)
