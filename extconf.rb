# -*- coding: utf-8 -*-
require 'mkmf'

dir_config('curses')
dir_config('ncurses')
dir_config('tinfo')

make=false
have_library("tinfo", "tgetent") if /bow/ =~ RUBY_PLATFORM
if have_header("ncurses.h") and have_library("ncurses", "initscr")
  make=true
elsif have_header("ncurses/curses.h") and have_library("ncurses", "initscr")
  make=true
elsif have_header("curses_colr/curses.h") and have_library("cur_colr", "initscr")
  make=true
else
  have_library("tinfo", "tgetent") 
  if have_library("curses", "initscr")
    make=true
  end
end

have_func("ttyname", "unistd.h")

if make
  for f in %w(isendwin beep flash doupdate)
    have_func(f)
  end
  create_makefile("jtcur")
end
