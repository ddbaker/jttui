
#
# maybe some might want better precision
# this is only a idea, how could s/he do it
#


class CalcNumber
  # arbitrary precision floating point numbers
  #
  # it is not very fast but, if you want speed use C and GNU multiple
  # precision arithmetic library (gmp)
  # 
  include Comparable
  attr_reader :ma, :ex, :si
  # number is stored as two bignums and fixnum: exponent, mantisa and sign
  # real number is sign*mantisa*(2**exponent) if sign is -1 or 1
  #
  # infinity state is signaled by sign variable also:
  # 0=Nan, 1=positive numer, -1=negative number, 2=Infinity, -2=-Infinity
  #
  # precision of mantisa is limited to MantisaPrec bits
  MantisaPrec=133 # this is about 40 decimal digits
  def initialize(ma,ex,si)
    @ma=ma; @ex=ex; @si=si
  end
  # number creation
  #
  def CalcNumber.nan;    CalcNumber.new(0,0,0)  end
  def CalcNumber.posinf; CalcNumber.new(0,0,2)  end
  def CalcNumber.neginf; CalcNumber.new(0,0,-2) end
  def CalcNumber.poszero;CalcNumber.new(0,0,1)  end
  def CalcNumber.negzero;CalcNumber.new(0,0,-1) end
  def CalcNumber.posone; CalcNumber.new(1,0,1)  end
  def CalcNumber.negone; CalcNumber.new(1,0,-1) end
  # number testing
  #
  def nan?;      @si==0  end
  def posinf?;   @si==2  end
  def neginf?;   @si==-2 end
  def poszero?; @si==1 and @ma==0 end
  def negzero?; @si==-1 and @ma==0 end
  def inf?; posinf? or neginf? end
  def zero?; poszero? or negzero? end
  def same!(other)
    raise StandardError,"expected CalcNumber, got #{other.class}",
      caller[1..-1] unless CalcNumber===other
  end
  # operators
  #
  def +(other)
    same! other
    return CalcNumber.nan if nan? or other.nan?
    if posinf?
      return CalcNumber.nan if other.neginf?
      return CalcNumber.posinf
    elsif neginf?
      return CalcNumber.nan if other.posinf?
      return CalcNumber.neginf
    else
      return CalcNumber.posinf if other.posinf?
      return CalcNumber.posinf if other.posinf?
    end
    e1=@ex; e2=other.ex
    m1=@ma; m2=other.ma
    s1=@si; s2=other.si
    ediff=e1-e2
    if ediff>0
      m2=m2 << ediff
      e=e1
    else
      m1=m1 << -ediff
      e=e2
    end
    m=m1+m2
# FIXME
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
    CalcNumber.new(Math.sin(self))
  end
  def cos
    CalcNumber.new(Math.sin(self))
  end
  def tan
    CalcNumber.new(Math.sin(self))
  end
  def sqrt
    CalcNumber.new(Math.sqrt(self))
  end
  def exp
    CalcNumber.new(Math.exp(self))
  end
  def log
    CalcNumber.new(Math.log(self))
  end
  def to_s(base=10)
    @@digits='0123456789abcdef' unless defined? @@digits
    return 'NaN' if @sign==0
    return 'Infinity' if @sign==2
    return '-Infinity' if @sign==-2
    x=@ma
    s=(@si<0) ? '-' : ''
    return s+'0.0' if x==0
    m=x; e=0
    while m<0.000001
      m*=1000000; e-=6
    end
    while m>=1000000
      m*=0.000001; e+=6
    end
    while m<0.1
      m*=10; e-=1
    end
    while m>=1
      m*=0.1; e+=1
    end
    ms=''
    numdigits=10
    while numdigits>0
      m*=base
      digit=m.truncate
      ms+=@@digits[digit,1]
      m-=digit
      numdigits-=1
    end
    return ms
  end
end

