#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# version 0.1.0

#
# Jakub Travnik's tui example
# this example uses widgets from jttuistd.rb
#
$: << File.dirname(__FILE__)

require "addlocalpath"
require "jttui/jttui"
require "jttui/jttuistd"

class DirEntry
  attr_reader :fullname, :shortname, :stat

  def initialize(fullname)
    @fullname = fullname
    @stat = File.stat(@fullname)
    @shortname = File.basename(@fullname)
    if @stat.directory?
      @fullname += "/"
      @shortname += "/"
    end
  end
end

class DirExpanderNode < JTTWTreeNodeCheckbox
  def initialize(*params, &block)
    @displaymode = 0
    super
  end

  def node_tryexpand
    if @datalink
      delayednotifyroot {
        node_collapse
        begin
          Dir.new(@datalink.fullname).to_a.each { |name|
            if name !~ /^\./ # dot-files not shown
              de = DirEntry.new(@datalink.fullname + name)
              newnode = DirExpanderNode.new(self, de, de.shortname)
            end
          }
        rescue
          # ignore access errors
        end
        subfiles = @subnodes.find_all { |x| !x.datalink.stat.directory? }.sort {
          |a, b|
          a.datalink.shortname <=> b.datalink.shortname
        }
        subdirs = @subnodes.find_all { |x| x.datalink.stat.directory? }.sort {
          |a, b|
          a.datalink.shortname <=> b.datalink.shortname
        }
        @subnodes = subdirs + subfiles
      }
    end
  end

  def node_getsize
    @label = @datalink.shortname
    if @displaymode >= 1
      @label += "\n " + @datalink.stat.ftype + " " + @datalink.stat.size.to_s + "B"
    end
    if @displaymode >= 2
      @label += "\n uid:#{@datalink.stat.uid} gid:#{@datalink.stat.gid}"
    end
    if @displaymode >= 3
      @label += "\n modified: " + @datalink.stat.mtime.to_s
    end
    super
  end

  def node_isexpandable?
    @datalink.stat.directory?
  end

  def node_collapse
    @subnodes = []
    notify
  end

  def node_key(key)
    if key == " "
      @displaymode += 1
      @displaymode = 0 if @displaymode > 3
      notifyroot
      true
    else
      super
    end
  end
end

class JTTWTreeDirs < JTTWTree
  def initialize(*params, &block)
    rootdirname = params.pop
    @rootnode = DirExpanderNode.new(nil, DirEntry.new("/"), "/")
    super(*params, &block)
    @rootnode.expand = true
  end
end

JTTui.run do |root|
  d1 = JTTDialog.new(root, "Dialog Window", 0, 0, 60, 16, "Example 4")
  d1.align = JTTWindow::ALIGN_CENTER
  l1 = JTTWLabel.new(d1, "Label1", 17, 12, 30, 2, "Press space to switch display mode for current item.")

  tr1 = JTTWTree.new(d1, "Tree list1", 1, 1, 15, 10)

  tr1_sub1 = JTTWTreeNodeLabel.new(tr1.rootnode, nil, "sub item 1")
  tr1_sub2 = JTTWTreeNodeLabel.new(tr1.rootnode, nil, "sub item 2")
  tr1_sub3 = JTTWTreeNodeLabel.new(tr1.rootnode, nil, "sub item 3")
  tr1_sub4 = JTTWTreeNodeLabel.new(tr1.rootnode, nil, "sub item 4")
  tr1_sub5 = JTTWTreeNodeLabel.new(tr1.rootnode, nil, "sub item 5")
  tr1_sub21 = JTTWTreeNodeLabel.new(tr1_sub2, nil, "sub item 2.1")
  tr1_sub211 = JTTWTreeNodeLabel.new(tr1_sub21, nil, "sub item 2.1.1")
  tr1_sub212 = JTTWTreeNodeLabel.new(tr1_sub21, nil, "sub item 2.1.2")
  tr1_sub31 = JTTWTreeNodeLabel.new(tr1_sub3, nil, "sub item 3.1")
  tr1_sub311 = JTTWTreeNodeLabel.new(tr1_sub31, nil, "sub item 3.1.1")
  tr1_sub3111 = JTTWTreeNodeLabel.new(tr1_sub311, nil, "sub item 3.1.1.1")
  tr1_sub51 = JTTWTreeNodeLabel.new(tr1_sub5, nil, "sub item 5.1")
  tr1_sub52 = JTTWTreeNodeLabel.new(tr1_sub5, nil, "sub item 5.2")

  tr2 = JTTWTreeDirs.new(d1, "Tree list1", 17, 1, 40, 10, "/")

  wbquit = JTTWButton.new(d1, "Test Button", 48, 13, 8, 1, "_Quit") {
    JTTui.addmessage nil, :close
  }
  d1.addtabstop tr1
  d1.addtabstop tr2
  d1.addtabstop wbquit
  d1.cancelbutton = wbquit
end
