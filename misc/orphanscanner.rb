#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# This is public domain, you may use it freely.
# There is no warranty of any kind that it will be working as described.
#
# this scans for identifiers in ruby programs that appear only once
# it is highly inaccurate but useable for finding stuff that left unused in
# source
#
# it does not scan libraries that programs include,
# you can do it by
# $ cat file1.rb lib1.rb lib2.rb |ruby orphanscanner.rb
#
# output format is: 'indentifier linenumber: linetext'
#


@a=[]
f=readlines
def outputs(s,i)
    s.scan(/\w+/).each{|x| @a << [x,i]}
end

def delnw(in0)
out=''
in1=in0.split /['"]/
state=0
in1.each{|x|
    out+=x if state==0
    if state==0
	state=1
    else
	state=0 unless x[-1]==?\\
    end
}
out.split('#')[0]
end

i=1
f.each do |fline|
    outputs delnw(fline),i
    i+=1
end
@a.sort!
h={}
@a.each do |z|
    x=z[0]
    h[x]=[0,0] unless h.key? x
    h[x]=[1+h[x][0],z[1].to_i]
end

h.each_pair do |k,v|
    if v[0]==1
	s=f[v[1]-1].chomp.strip
	ss=(k.chomp+" #{v[1]}:").ljust 18
	print ss,s,"\n"
    end
end
