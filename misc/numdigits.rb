#/usr/bin/env ruby -w

# we need to know how many digits to display, this is base dependent
# table below have them precomputed. This computation was based on

eb=11    # bits in exponent (including exponent sign)
mb=52-4  # bits in mantisa (excluding sign, it is independent),
         # I consider last 4 to be inexact so I'm ignoring them
# values above are valid for 8byte IEEE double floating point

maxwidth=45 # maximum available width for displaing value
internal_width=5 # other characters in number 'E', '.' ,'+' , '-'
   # and place for one digit extension in rounding 9.999999999 -> 10.000000000

def log(x,base) # logarithm of some base
 Math.log(x)/Math.log(base)
end

def width_of_mantisa(eb,base)
# number of character for longest exponent without a sign
  (log(2**eb*log(2,base),base)).ceil
end

def maximum_precision_in_digits(mb,base)
  (mb*log(2,base)).floor
end

ary=(2..16)
ary=ary.collect{|x|
  [ maximum_precision_in_digits(mb,x),
    maxwidth-internal_width-width_of_mantisa(eb,x)].min
}
p ary

