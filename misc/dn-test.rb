# -*- coding: utf-8 -*-
#
# this test example for DelayedNotify pattern from jtutil.rb
#

require 'jtutil.rb'

class AverageOfTwo
  attr_reader :valueone, :valuetwo, :average
  include DelayedNotify
  def initialize(v1,v2)
    @valueone=v1; @valuetwo=v2
    delayednotify_init { @average=(@valueone+@valuetwo)/2.0 }
    notify
  end
  def valueone=(v); @valueone=v; notify; end
  def valuetwo=(v); @valuetwo=v; notify; end
end
aot=AverageOfTwo.new(1,3)
p aot.average
aot.valueone=6
p aot.average
aot.delayednotify {
  aot.valueone=20  # no update here
  aot.valuetwo=10  # no update here
}  # <-- update occur here
p aot.average
