#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'addlocalpath'
require 'jttui/jttui'
require 'jttui/jttuistd'

# get root
runmain,root=callcc{ |c1|
  JTTui.run{ |root|
    callcc{ |c2|
      c1.call(c2,root)
    }
  }
  $c3.call
}


# your stuff
d1=JTTDialog.new(root, 'Dialog Window', 0, 0, 60, 16,
		 'Example')
d1.align=JTTWindow::ALIGN_CENTER
bq=JTTWButton.new(d1, 'Quit Button', 3, 2, 11, 1, 'Quit') {
    JTTui.addmessage nil, :close}
d1.addtabstop bq



# run mainloop if you want
callcc{ |$c3|
  runmain.call
}
