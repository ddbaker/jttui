# -*- coding: utf-8 -*-

# this works but cannot be run from midnight commander (when using gpm)
# did you noticed that even mc run from mc don't have working mouse?

#/usr/include/asm/ioctls.h:#define TIOCLINUX     0x541C

TIOCLINUX=0x541C

def drawpointer(x,y,f)
command=[2,x+1,y+1,x+1,y+1,3].pack 'CSSSSS'
f.ioctl(TIOCLINUX, command)
end

#File.open('/dev/tty2',"w") do |f|
f=$stdin
sleep 1
drawpointer 10,11,f
sleep 1
drawpointer 10,12,f
sleep 1
drawpointer 11,12,f
sleep 1
drawpointer 12,12,f
sleep 1
#end
