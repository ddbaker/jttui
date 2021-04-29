#!/usr/bin/env ruby

# version 0.1.0

#
# Jakub Travnik's tui example
# this example uses widgets from jttuistd.rb
# and localization stuff from jtloc.rb
#

#
# It uses idea of separated back-end (class CalcNumber and Calculator) and
# front-end (user interface). I recomend this coding style for any project
# using JTTui or user interface generally. It is easily maintainable.
# Calculator class can be tested without UI just from irb.
#

require 'addlocalpath'
require 'jttui/jttui'
require 'jttui/jttuistd'
require 'jttui/jtloc'


class CalcNumber
  # we use Float numbers, but some may need/want to change it
  # to something with better precision (there is discontinued arbitrary
  # floating point number class in misc/calcnum.rb)
  #
  # CalcNumber can read numbers from string in bases of 2 to 16 all including
  # exponentation (in that base also)
  # i.e. CalcNumber.new('ab.cE-d',16)
  #  have value of 3.81361609e-14 (in dec., approx.)
  #
  # CalcNumber also eliminate need for using Math module directly
  include Comparable
  attr_accessor :value
  def initialize(v,base=10)
    case v
    when Float,Integer
      @value=v.to_f
    when String
      if v==''
	@value=0.0
	return
      end
      pointbase=nil; number=nil; exponent=nil; sign=nil; expsign=nil
      haveexponent=false
      v.each_byte{|b|
	if b==?+
	  if exponent
	    raise -'too many signs in exponent' if expsign
	    raise -'exponent have embedded sign' if haveexponent
	    expsign=1
	  else
	    raise -'too many signs in mantisa' if sign
	    raise -'mantisa have embedded sign' if number
	    sign=1
	  end
	elsif b==?-
	  if exponent
	    raise -'too many signs in exponent' if expsign
	    raise -'exponent have embedded sign' if haveexponent
	    expsign=-1
	  else
	    raise -'too many signs in mantisa' if sign
	    raise -'mantisa have embedded sign' if number
	    sign=-1
	  end
	elsif b==?.
	  raise -'decimal point cannot be in exponent' if exponent
	  raise -'too many decimal points' if pointbase
	  pointbase=1
	  number=0 unless number
	elsif b==?E
	  raise -'too many exponent signs' if exponent
	  exponent=0
	elsif exponent
	  d=getdigit b,base
	  raise -'invalid digit' unless d
	  haveexponent=true
	  exponent=base*exponent+d
	else
	  number=0 unless number
	  d=getdigit b,base
	  raise -'invalid digit' unless d
	  number=base*number+d
	  if pointbase
	    pointbase*=base
	  end
	end
      }
      raise -'invalid number' unless number or exponent
      raise -'empty exponent' if exponent and not haveexponent
      sign=1 unless sign
      number=1 unless number
      exponent=0 unless exponent
      expsign=1 unless expsign
      pointbase=1 unless pointbase
      @value=sign*(number.to_f/pointbase)*(base**(expsign*exponent))
    else
      raise "value #{v} cannot be converted to CalcNumber"
    end
  end
  def getdigit(code,base)
    # FIXME: index is slow, use inverse of digits
    @@digits='0123456789abcdef' unless defined? @@digits
    d=@@digits.index code
    d ? (d<base ? d : nil) : nil
  end
  def to_s(base=10)
    @@digits='0123456789abcdef' unless defined? @@digits
    x=@value
    if x < 0
      s='-'; x=-x
    else
      s=''
    end
    return -'NaN' if x.nan?
    return s + -'Infinity' unless x.finite?
    return s+'0' if x.zero?
    baser=1.0/base
    base8=base*base; base8=base8*base8; base8=base8*base8
    baser8=baser*baser; baser8=baser8*baser8; baser8=baser8*baser8
    m=x; e=0
    while m<baser8
      m*=base8; e-=8
    end
    while m>=base8
      m*=baser8; e+=8
    end
    while m<baser
      m*=base; e-=1
    end
    while m>=1
      m*=baser; e+=1
    end
    ms=''
    # we need to know how many digits to display, this is base dependent
    # table below have them precomputed. This computation was based on
    # eb=11 # bits in exponent (including exponent sign)
    # mb=52-4 # bits in mantisa (excluding sign, it is independent),
    #         # I consider last 4 to be inexact so I'm ignoring them
    # maxwidth=45 # maximum available width for displaing value
    # internal_wodth=5 # other characters in numbers: 'E', '.', '-', '+'
    # # values above are valid for 8byte IEEE double floating point
    # def log(x,base); Math.log(x)/Math.log(base) end # logarithm of some base
    # def width_of_mantisa(eb,base)
    # # number of character for longest exponent without a sign
    #   (log(2**eb*log(2,base),base)).ceil
    # end
    # def maximum_precision_in_digits(mb,base)
    #   (mb*log(2,base)).floor
    # end
    # (2..16).collect{|x|
    #   [ maximum_precision_in_digits(mb,x),
    #     maxwidth-internal_width-width_of_mantisa(eb,x)].min
    # }
    #
    # this can be found in source distribution in ./misc/numdigist.rb
    numdigits=[29, 30, 24, 20, 18, 17, 16, 15, 14,
      13, 13, 12, 12, 12, 12][base-2]
    while numdigits>0
      m*=base
      digit=m.truncate
      ms+=@@digits[digit,1]
      m-=digit
      numdigits-=1
    end
    if getdigit(ms[-1],base)==base-1
      # round to up if something like 119999999999 is generated
      idx=ms.length-1
      begin
	ms[idx]=?0
	idx-=1
	d=getdigit(ms[idx],base)
      end while d==base-1
      if d
	ms[idx]=@@digits[d+1,1]
      else
	ms='1'+ms; e+=1
	break
      end
    end
    if e>=0 and e<14
      len=ms.length
      ms << '0'*(e-len+1) unless len>e
      ms[e,0]='.'
      ms.gsub!(/(\..*?)0+$/,'\1') # clear tail zeroes
      ms.gsub!(/\.$/,'')          # remove tail point if it is there
      ms=s+ms
    else
      ms[1,0]='.'
      ms.gsub!(/(\..*?)0+$/,'\1') # clear tail zeroes
      exp=''; e-=1
      if e<0
	exps='-'
	e=-e
      else
	exps=''
      end
      while e>0
	e,ed=e.divmod base
	exp=@@digits[ed,1]+exp
      end
      ms=s+ms+'E'+exps+exp
    end
    return ms
  end
  def +(other)
    CalcNumber.new(self.value+other.value)
  end
  def -(other)
    CalcNumber.new(self.value-other.value)
  end
  def *(other)
    CalcNumber.new(self.value*other.value)
  end
  def /(other)
    CalcNumber.new(self.value/other.value)
  end
  def **(other)
    CalcNumber.new(self.value**other.value)
  end
  def -@
    CalcNumber.new(-self.value)
  end
  def <=>(other)
    @value<=>other
  end
  def sin
    CalcNumber.new(Math.sin(@value))
  end
  def cos
    CalcNumber.new(Math.cos(@value))
  end
  def tan
    CalcNumber.new(Math.sin(@value)/Math.cos(@value))
  end
  def asin
    CalcNumber.new(@value/Math.sqrt(1-@value*@value)).atan
  rescue
    return CalcNumber.nan
  end
  def acos
    return CalcNumber.pi/CalcNumber.two if @value==0
    CalcNumber.new(Math.sqrt(1-@value*@value)/@value).atan
  rescue
    return CalcNumber.nan
  end
  def atan
    CalcNumber.new(Math.atan2(@value,1))
  end
  def n!
    if (@value % 1)==0.0 and @value>=0.0
      arg=@value.to_i
      return CalcNumber.nan if arg>1000
      CalcNumber.new(_n!(arg))
    else
      CalcNumber.nan
    end
  end
  def _n!(n)
    res=1
    while n>1
      res*=n; n-=1
    end
    res
  end
  def sqrt
    CalcNumber.new(Math.sqrt(@value))
  rescue
    return CalcNumber.nan
  end
  def exp
    CalcNumber.new(Math.exp(@value))
  end
  def ln
    CalcNumber.new(Math.log(@value))
  rescue
    return CalcNumber.nan
  end
  def log10
    CalcNumber.new(Math.log10(@value))
  rescue
    return CalcNumber.nan
  end
end
def CalcNumber.pi
  CalcNumber.new(Math::PI)
end
def CalcNumber.zero
  CalcNumber.new(0.0)
end
def CalcNumber.one
  CalcNumber.new(1.0)
end
def CalcNumber.minusone
  CalcNumber.new(-1.0)
end
def CalcNumber.two
  CalcNumber.new(2.0)
end
def CalcNumber.posinf
  (CalcNumber.one/CalcNumber.zero)
end
def CalcNumber.neginf
  (CalcNumber.minusone/CalcNumber.zero)
end
def CalcNumber.nan
  CalcNumber.posinf*CalcNumber.zero
end

class Calculator
  attr_reader :stack,:editing,:base,:error,:angleunit
  def initialize
    @prihash={'='=>0,')'=>1,'('=>1,'+'=>2,'-'=>2,'*'=>3,'/'=>3,'^'=>4}
    @base=10
    # the number is multiplied by this before processing if it is angle input
    # or divided by this if result is angle
    @angleunits={'RAD'=>CalcNumber.one,
      'DEG'=>CalcNumber.pi/CalcNumber.new(180),
      'GRD'=>CalcNumber.pi/CalcNumber.new(200)}
    @angleunit='RAD'
    reset
  end
  def reset
    @stack=[CalcNumber.zero]
    @typednum=''
    @editing=true
    @memory=CalcNumber.zero
    @error=nil
  end
  def base=(v)
    case base
    when 2,8,10,16
      endeditmode if @editing
      @base=v
    else
      raise -'unsupported base'
    end
  end
  def setangleunit(v,convert=false)
    raise "unknown angle unit '#{v}'" unless @angleunits[v]
    if convert
      i=getlastvalueindex
      @stack[i]=@stack[i]*@angleunits[@angleunit]/@angleunits[v] if i
    end
    @angleunit=v
  end
  def angletorad(x)
    x*@angleunits[@angleunit]
  end
  def radtoangle(x)
    x/@angleunits[@angleunit]
  end
  def typenum(s)
    return if @error
    case s
    when '.'
      # only one decimal point and only in mantisa
      unless @typednum.index 'E'
	@typednum+=s unless @typednum.index '.'
      end
    when 'E'
      # only first exponentation makes sense
      @typednum+=s unless @typednum.index 'E'
    when '+/-'
      # sign change key
      if @typednum.index 'E'
	# change sign of exponent
	signindex=1+@typednum.index('E')
	case @typednum[signindex,1]
	when nil
	  @typednum+='-'
	when '-'
	  @typednum[signindex,1]=''
	else
	  @typednum[signindex,0]='-'
	end
      else
	# without exp notation, change leading sign
	if @typednum[0,1]=='-'
	  @typednum=@typednum[1..-1]
	else
	  @typednum='-'+@typednum
	end
      end
    when 'backspace'
      @typednum=@typednum[0..-2] if @typednum.length>0
    when '0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'
      # numbers are appended
      @typednum+=s if '0123456789abcdef'.index(s)<@base
    end
  end
  def function?(k)
    ['MR','MC','MS','M+',
      'SIN','COS','TAN',
      'ASIN','ACOS','ATAN',
      'SQR','SQRT','1/x','n!',
      'LN','EXP','10^x','LOG',
      'const_pi','const_e'].include? k
  end
  def endeditmode
    if @editing
      begin
	value=CalcNumber.new(@typednum,base)
      rescue
	@error=$!.message
	value=CalcNumber.nan
      end
      if stack[-1].kind_of? CalcNumber
	stack[-1]=value
      else
	stack << value
      end
      @editing=false
      @typednum=''
    end
  end
  def enterconst(value)
    if @typednum.length==0
      if @stack.length>1 and @stack[-1].kind_of?(CalcNumber)
	    @error=-'missing operator'
      else
	if @stack[-1].kind_of?(CalcNumber)
	  @stack[-1]=value
	else
	  @stack << value
	end
      end
    else
      @error=-'missing operator'
    end
    @editing=false
    @typednum=''
  end
  def starteditmode
    if @stack.length>1 and @stack[-1].kind_of?(CalcNumber)
      @error=-'operation was expected'
    end
    @typednum=''
    @editing=true
  end
  def processkey(k)
    return if @error and (k != 'AC')
    if @editing
      if ['=',')','+','-','*','/','^','AC'].include?(k) or function?(k)
	endeditmode
	processkey k
      elsif k=='('
	if @typednum.length==0
	  if @stack.length>1 and @stack[-1].kind_of?(CalcNumber)
	    @error=-'missing operator'
	  else
	    if @stack[-1].kind_of?(CalcNumber)
	      @stack[-1]=k
	    else
	      @stack << k
	    end
	  end
	else
	  @error=-'missing operator'
	end
      elsif k=='+/-'
	if @typednum.length>0
	  typenum k
	else
	  endeditmode
	  processkey k
	end
      else
	typenum k
      end
    else
      if function? k
	processfunction k
      else
	if k=='AC'
	  reset
	else
	  case k
	  when '=',')','+','-','*','/','^'
	    if @stack[-1].kind_of? CalcNumber
	      @stack << k
	      compute
	    else
	      @error=-'no number'
	    end
	  when '+/-'
	    @stack[-1]=-@stack[-1]	    
	  else
	    starteditmode
	    processkey k
	  end
	end # if k=='AC'
      end
    end
  end
  def processfunction(k)
    case k
    when 'MR'    # memory functions are not yet used in calculator
      enterconst(@memory)
    when 'MC'
      @memory=CalcNumber.zero
    when 'const_pi'
      enterconst(CalcNumber.pi)
    when 'const_e'
      enterconst(CalcNumber.one.exp)
    else
      unless @stack[-1].kind_of?(CalcNumber)
	@error=-'value required'
	return
      end
      case k
      when 'MS'
	@memory=@stack[-1]
      when 'M+'
	@memory+=@stack[-1]
      when 'SIN'
	@stack[-1]=angletorad(@stack[-1]).sin
      when 'COS'
	@stack[-1]=angletorad(@stack[-1]).cos
      when 'TAN'
	@stack[-1]=angletorad(@stack[-1]).tan
      when 'ASIN'
	@stack[-1]=radtoangle(@stack[-1].asin)
      when 'ACOS'
	@stack[-1]=radtoangle(@stack[-1].acos)
      when 'ATAN'
	@stack[-1]=radtoangle(@stack[-1].atan)
      when 'SQR'
	@stack[-1]*=@stack[-1]
      when 'SQRT'
	@stack[-1]=(@stack[-1]).sqrt
      when '1/x'
	@stack[-1]=CalcNumber.one/@stack[-1]
      when 'n!'
	@stack[-1]=@stack[-1].n!
      when 'LN'
	@stack[-1]=@stack[-1].ln
      when 'EXP'
	@stack[-1]=@stack[-1].exp
      when 'LOG'
	@stack[-1]=@stack[-1].log10
      when '10^x'
	@stack[-1]=CalcNumber.new(10)**@stack[-1]
      else
	raise "bug: function '#{k}' is unknown to calculator"
      end
    end
  end
  def compute
    begin
    changed=false
      pritop=@prihash[@stack[-1]]
      if pritop
	(@stack.length-2).downto(0){|pos|
	  if @stack[pos].kind_of? String
	    pricur=@prihash[@stack[pos]]
	    if pricur<pritop
	    break
	    else
	      changed=true
	      computeat(pos)
	      break
	    end
	  end
	}
      end
    end while changed
    @stack.delete_at(-1) if @stack[-1]=='='
  end
  def computeat(pos)
    # FIMXE: add error handling
    case @stack[pos]
    when '('
      @stack[pos]=@stack[pos+1]
      @stack.delete_at pos+1
      @stack.delete_at pos+1
    when '+'
      @stack[pos-1]+=@stack[pos+1]
      @stack.delete_at pos
      @stack.delete_at pos
    when '-'
      @stack[pos-1]-=@stack[pos+1]
      @stack.delete_at pos
      @stack.delete_at pos
    when '*'
      @stack[pos-1]*=@stack[pos+1]
      @stack.delete_at pos
      @stack.delete_at pos
    when '/'
      @stack[pos-1]/=@stack[pos+1]
      @stack.delete_at pos
      @stack.delete_at pos
    when '^'
      @stack[pos-1]=((@stack[pos-1]).ln*@stack[pos+1]).exp
      @stack.delete_at pos
      @stack.delete_at pos
    end
  end
  def getlastvalueindex
    i=0
    @stack.reverse_each{|x| i-=1; return i if x.kind_of?(CalcNumber) }
    nil
  end
  def getlastvalue
    i=getlastvalueindex
    i ? @stack[i] : nil
  end
  def getvalue
    if @error
      @error
    elsif @typednum.length>0
      @typednum
    else
      lv=getlastvalue
      lv ? lv.to_s(@base) : '0'
    end
  end
end

class LCDLabel < JTTWindow
  attr_reader :caption
  def initialize(*params)
    @caption=params.pop
    super(*params)
  end
  def paintself(pc)
    super
    pc.windowframe self,@color
    pc.move 2,1
    pc.addstra @caption.rjust(self.w-4),JTTui.color_lcd
  end
  def caption=(v)
    @caption=v
    addmessage self,:paint
  end
end

class CalcButton < JTTWButton
  attr_reader :help
  attr_accessor :helphandler, :postaction
  def initialize(parent,label,other_hotkeys,help, &block)
    super(parent, 'CalcButton', 0, 0, 7, 1, label, &block)
    other_hotkeys.each{|keyname| self.hl_addone keyname} if other_hotkeys
    @help=help
    @helphandler=nil
    @postaction=nil
  end
  def gotfocus
    super
    @helphandler.call(self) if @helphandler
  end
  def action
    super
    @postaction.call if @postaction
  end
  def keypress(k)
    case k
    when 'C-j','C-m'  # ignore enter key
      addmessage @parent, :keypress, k
    else
      super
    end
  end
end


JTLanguage.load_locale('./example-jttuistd-2-calculator-lang')
# JTLanguage.write_missing

JTTui.run do |root|
  c=Calculator.new
  JTTui.colors << JTTColor.new('color_lcd',
			       JTCur.color_black,JTCur.color_green,0,
			       JTCur.attr_bold).recompute
  JTTui.colors << JTTColor.new('color_calc',
			       JTCur.color_white,JTCur.color_blue,0,
			       0).recompute
  JTTui.colors << JTTColor.new('color_calc_hi',
			       JTCur.color_yellow,JTCur.color_blue,
			       JTCur.attr_bold, JTCur.attr_bold).recompute
  cw=JTTDialog.new(root, 'Calculator Window', 0, 0, 56, 19,
		   -'Ruby/JTTui Calculator')
  cw.align=JTTWindow::ALIGN_CENTER
  bq=JTTWButton.new(cw, 'Quit Button', 0, 0, 8, 1, -'_Quit') {
    JTTui.addmessage nil,:close}
  lcd=LCDLabel.new(cw, 'LC Display Label', 2, 2, 49, 3, '0')
  helplabel=JTTWLabel.new(cw, 'Help Label', 2, 14, 52, 3, '')
  helpcheck=JTTWCheckbox.new(cw,'Help check',26,0,13,1,-'Show _help') {
    helplabel.caption=''
  }
  baselabel=JTTWLabel.new(cw, 'Base Label', 2, 1, 8, 1, '')
  anglelabel=JTTWLabel.new(cw, 'Angle Label', 13, 1, 9, 1, '')
  stacklabel=JTTWLabel.new(cw, 'Stack Label', 2, 5, 49, 1, '')
  stackcheck=JTTWCheckbox.new(cw,'Stack check',40,0,14,1,-'Show stack') {
    stacklabel.caption=''
  }
  helpcheck.state=1
  g=JTTWGrid.new(cw,'Button Grid',3,6,47,8)

  [g,cw,lcd,helplabel,helpcheck,baselabel,anglelabel,
    stacklabel,stackcheck].each{ |x|
    x.color=JTTui.color_calc
    x.color_hi=JTTui.color_calc_hi if defined? x.color_hi
  }

  m_yes_no=JTTWMessagebox.new('',0,-1,-'_Yes',-'_No')

  m_angle=JTTWMessagebox.new(-'Choose angle units',0,-1,'_RAD','_DEG','_GRD')
  m_base=JTTWMessagebox.new(-'Choose base of numbers',2,-1,
			    '2 (_BIN)','8 (_OCT)','10 (_DEC)','16 (_HEX)')

# mapping of calculator keys
#                [  f  ] [sqrt ] [ e^x ] [ ln  ] [10^x ] [ log ]
#                [  e  ] [ x^2 ] [asin ] [acos ] [atan ] [ y^x ]
#                [  d  ] [ n!  ] [ sin ] [ cos ] [ tan ] [ 1/x ]
#                [  c  ] [ Exp ] [ +/- ] [  (  ] [  )  ] [ <-  ]
#                [  b  ] [BASE ] [  7  ] [  8  ] [  9  ] [  /  ]
#                [  a  ] [ANGLE] [  4  ] [  5  ] [  6  ] [  *  ]
#                [ Pi  ] [ ALT ] [  1  ] [  2  ] [  3  ] [  -  ]
#                [  e  ] [  C  ] [  0  ] [  .  ] [  =  ] [  +  ]
# top left button is b11, bottom right is b86
# digits in button identifier indicate its coordinates

  hexbuttonhelp=-"Inserts &1 digit in hexadecimal (HEX) base.\nkey: &1"
  b11=CalcButton.new(g, '_f', nil,
		     hexbuttonhelp & 'f') { c.processkey 'f' }
  b12=CalcButton.new(g, 'sqrt', ['s'],
		     -("Square root of value,"+
		     " fails for negative argument.\nkey: s")) {
    c.processkey 'SQRT'
  }
  b13=CalcButton.new(g, 'e^x', ['['],
		     -"Euler number powered to value.\nkey: [") {
    c.processkey 'EXP'
  }
  b14=CalcButton.new(g, 'ln', [']'],
		     -("Natural logarithm of value,"+
		     " fails for negative argument.\nkey: ]")) {
    c.processkey 'LN'
  }
  b15=CalcButton.new(g, '10^x', ['{'],
		     -"10 powered to value.\nkey: {") {
    c.processkey '10^x'
  }
  b16=CalcButton.new(g, 'log', ['}'],
		     -("base 10 logarithm,"+
		     " fails for negative argument.\nkey: }")) {
    c.processkey 'LOG'
  }

  b21=CalcButton.new(g, '_e', nil,
		     hexbuttonhelp & 'e') { c.processkey 'e' }
  b22=CalcButton.new(g, 'x^2', nil,
		     -"Square of number.") { c.processkey 'SQR' }
  b23=CalcButton.new(g, 'asin', nil,
		     -("Inverse operation for sin,"+
		     " fails for argument outside -1 to 1.\n")) {
    c.processkey 'ASIN'
  }
  b24=CalcButton.new(g, 'acos', nil,
		     -("Inverse operation for cos,"+
		     " fails for argument outside -1 to 1.")) {
    c.processkey 'ACOS'
  }
  b25=CalcButton.new(g, 'atan', nil,
		     -"Inverse operation for tangent.") {
    c.processkey 'ATAN'
  }
  b26=CalcButton.new(g, 'y_^x', nil,
		     -("y powered to x, fails for negative y.\n"+
		     "keys: ^")) {
    c.processkey '^'
  }

  b31=CalcButton.new(g, '_d', nil,
		     hexbuttonhelp & 'd') { c.processkey 'd' }
  b32=CalcButton.new(g, 'n_!', nil,
		     -("Factorial. Only for integer argument.\n"+
		     "keys: !")) {
    c.processkey 'n!'
  }
  b33=CalcButton.new(g, 'sin', nil,
		     -"Sinus.") { c.processkey 'SIN' }
  b34=CalcButton.new(g, 'cos', nil,
		     -"Cosinus.") { c.processkey 'COS' }
  b35=CalcButton.new(g, 'tan', nil,
		     -"Tangent, fails for singular points.") {
    c.processkey 'TAN'
  }
  b36=CalcButton.new(g, '1/x',['r'],
		     -("One divided by argument. Fails for zero.\n"+
		     "keys: r")) {
    c.processkey '1/x'
  }

  b41=CalcButton.new(g, '_c', nil,
		     hexbuttonhelp & 'c') { c.processkey 'c' }
  b42=CalcButton.new(g, 'E_xp', nil,
		     -("Use to enter exponent as usually"+
		     " in engineering notation.\nkeys: x")) {
    c.processkey 'E'
  }
  b43=CalcButton.new(g, '+/-',['i'],
		     -"Swap sign of number or its exponent.\nkeys: i") {
    c.processkey '+/-'
  }
  b44=CalcButton.new(g, '_(', nil,
		     -"Opening parenthesis for new grouping.\nkeys: (") {
    c.processkey '('
  }
  b45=CalcButton.new(g, '_)', nil,
		     -"Closing parenthesis to finish grouping.\nkeys: )") {
    c.processkey ')'
  }
  b46=CalcButton.new(g, '<-',['backspace','del','C-h'],
		     -"Erase last digit.\nkeys: backspace, del, C-h") {
    c.processkey 'backspace'
  }

  b51=CalcButton.new(g, '_b', nil,
		     hexbuttonhelp & 'b') { c.processkey 'b' }
  b52=CalcButton.new(g, 'BASE', nil,
		     -("Change base for displaying and entering numbers. "+
		     "Current number is converted.")) {
    mres=m_base.execute
    case mres
    when 0 then c.base=2
    when 1 then c.base=8
    when 2 then c.base=10
    when 3 then c.base=16
    end
    m_base.defaultnr=mres unless mres==-1
  }
  b53=CalcButton.new(g, '_7', nil, "") { c.processkey '7' }
  b54=CalcButton.new(g, '_8', nil, "") { c.processkey '8' }
  b55=CalcButton.new(g, '_9', nil, "") { c.processkey '9' }
  b56=CalcButton.new(g, '_/', nil,
		     -"Division. Fails for zero denominator.\nkeys: /") {
    c.processkey '/'
  }

  b61=CalcButton.new(g, '_a', nil,
		     hexbuttonhelp & 'a') { c.processkey 'a' }
  b62=CalcButton.new(g, 'ANGLE', nil,
		     -("Change angle units. Current number is converted "+
		     "or not depending on user choose.")) {
    c.endeditmode
    mres=m_angle.execute
    if mres>=0
      m_angle.defaultnr=mres
      myn=m_yes_no.execute -'Convert current value?'
      if myn>=0
	c.setangleunit(['RAD','DEG','GRD'][mres], myn==0)
      end
    end
  }
  b63=CalcButton.new(g, '_4', nil, "") { c.processkey '4' }
  b64=CalcButton.new(g, '_5', nil, "") { c.processkey '5' }
  b65=CalcButton.new(g, '_6', nil, "") { c.processkey '6' }
  b66=CalcButton.new(g, '_*', nil,
		     -"Multiply operator.\nkeys: *") { c.processkey '*' }

  b71=CalcButton.new(g, 'Pi', nil,
		     -"Circumference ratio constant.") {
    c.processkey 'const_pi'
  }
  b72=CalcButton.new(g, 'AL_T', nil, "Alternate functions.\n"+
		     "Not yet implemented") { }
  b73=CalcButton.new(g, '_1', nil, "") { c.processkey '1' }
  b74=CalcButton.new(g, '_2', nil, "") { c.processkey '2' }
  b75=CalcButton.new(g, '_3', nil, "") { c.processkey '3' }
  b76=CalcButton.new(g, '_-', nil,
		     -"Substraction operator.\nkeys: -") { c.processkey '-'}

  b81=CalcButton.new(g, 'e', nil,
		     -"Euler constant.") {
    c.processkey 'const_e'
  }
  b82=CalcButton.new(g, 'C', ['esc','C-c'],
		     -"Clear all.\nkeys: C-c, esc (two times)") {
    c.processkey 'AC'
  }
  b83=CalcButton.new(g, '_0', nil, "") { c.processkey '0' }
  b84=CalcButton.new(g, '_.', nil, -"Decimal dot.\nkeys: .") {
    c.processkey '.'
  }
  b85=CalcButton.new(g, '_=', ['C-j','C-m'],
		     -"Finish computation.\nkeys: =, enter, C-m, C-j") {
    c.processkey '='
  }
  b86=CalcButton.new(g, '_+', nil, -"Addition operator.\nkeys: +") { 
    c.processkey '+'
  }

  helphandler=Proc.new{ |obj|
    if helpcheck.state==1
      text=-("Use arrows, tab, M-tab, C-f, C-b, C-n, C-p to move.\n"+
	"Use space to activate buttons.\nEnter key act as = key.")
      text=obj.help if obj.help.length>0
      helplabel.caption=text
    end
  }
  showhandler=Proc.new{
    lcd.caption=c.getvalue
    if stackcheck.state==1
      st='Stack: '; stlw=stacklabel.w-st.length
      st=st+c.stack.join(' ').ljust(stlw)[-stlw .. -1]
      stacklabel.caption=st
    end
    baselabel.caption=-"Base: &1" & c.base.to_s
    anglelabel.caption=-"Mode: &1" & c.angleunit
  }
  showhandler.call
  g.subwindows.each{|b|
    b.color=JTTui.color_calc
    b.color_hi=JTTui.color_calc_hi
    b.helphandler=helphandler
    b.postaction=showhandler
  }
  g.setcontent(1,0,
               [b11,b12,b13,b14,b15,b16],
	       [b21,b22,b23,b24,b25,b26],
	       [b31,b32,b33,b34,b35,b36],
	       [b41,b42,b43,b44,b45,b46],
	       [b51,b52,b53,b54,b55,b56],
	       [b61,b62,b63,b64,b65,b66],
	       [b71,b72,b73,b74,b75,b76],
	       [b81,b82,b83,b84,b85,b86])
  
  cw.addtabstop bq
  cw.addtabstop helpcheck
  cw.addtabstop stackcheck
  cw.cancelbutton=b82
  cw.settab b64
  lcd.down
end
