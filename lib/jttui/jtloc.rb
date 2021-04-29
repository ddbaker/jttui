#
# Jakub Travnik's textmode user interface
# language localization
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

#
# intended usage:
# program called myprogram will call:
# JTLanguage.load_locale('path/myprogram')
# and now all strings with unary minus will be translated
#
# How it works:
# JTLanguage will load file path/myprogram.localename
# where locale name is derived from standard locale variables such
# as LC_MESSAGES, LC_ALL, LANG (tried in that order)
#
# localization file contain lines with following structure:
#  1, meaning of any character is changed if it is prefixed with backslash
#  2, anything after # character is comment, so it is ignored
#  3, line contain one equal character (=) that delimits original and
#     translated text
#  4, following translation appear (transformation appear in parallel):
#     \\ -> \
#     \# -> #
#     \= -> =
#     backslash followed by exactly three octal digits means character
#      of that code
#     backslash followed by x or X and exactly two hexadecimal digits means
#      character of that code
#
# note 1: call JTLanguage.write_missing before starting to translate strings
#         to generate skeleton of file or append new (untranslated) strings
# note 2: use String.& for text substitutions
#         (languages have various order of words)
# note 3: this format and implementation should allow to use UTF-8 encoding
#         of characters without any problems
#
# example of translation file myprog.cs (iso-8859-2 encoding):
#   Hello World!=Ahoj sv\xecte!# character using hex
#   Hello World!!=Ahoj sv\354te!!# character using octal
#   # such character can be entered as is but then it is unreadable for those
#   # with other code pages so I don't use it in this example
#   # however, in real world I recommend using extended character directly
#   \#, \\ and \= characters =Znaky \#, \\ a \= # escaped characters
# use of example (assuming bash shell, $ is prompt)
#  $ ls
#  myprog.cs	myprog.rb
#  $ cat myprog.rb
#  require 'jtloc'
#  JTLanguage.load_locale('myprog')
#  p 'Hello World!', 'Hello World!!', '#, \ and = characters'
#  p -'Hello World!', -'Hello World!!', -'#, \ and = characters'
#  $ echo $LC_MESSAGES
#  cs
#  $ ruby myprog.rb
#  "Hello World!"
#  "Hello World!!"
#  "#, \\ and = characters "
#  "Ahoj sv\354te!"
#  "Ahoj sv\354te!!"
#  "Znaky #, \\ a = "
#  $
# note that space before comment character is significant (see it in example)
#

class String
  def -@
    JTLanguage.translate(self)
  end
  # & make easy text substitution (for up to 9 substitutions)
  # ex. a='start &2 &1 && end'
  #     a & 'hello' => 'start &2 hello & end'
  #     a & ['hello'] => 'start &2 hello & end'
  #     a & ['hello','world'] => 'start world hello & end'
  def &(arg)
    arg=[arg] if String===arg
    res=self.dup
    arg.each_with_index{ |x,i|
      res.gsub!('&'+(i+1).to_s,x)
    }
    res.gsub!('&&','&')
    res
  end
end

module JTLanguage
  extend self
  def load_locale(basename)
    @localehash={} 
    langname=ENV['LC_MESSAGES']
    langname=ENV['LC_ALL'] unless langname
    langname=ENV['LANG'] unless langname
    if langname
      unless langname=~/[a-zA-Z_0-9]+/ # for file safety
	raise "invalid locale environment variable: #{langname}"
      end
      @langname=''
      @localefile=basename+'.'+langname
      begin
	File.open(@localefile){ |f|
	  @langname=langname
	  lines=f.readlines.grep /^[^#]/ # remove empty and comment lines
	  lines.collect!{ |line|
	    commentpos=line.index(/[^\\]#/)
	    commentpos ? line[0...commentpos] : line.chomp
	  }
	  linenr=0
	  lines.each{ |line|
	    linenr+=1
	    eqpos=line.index(/[^\\]=/)
	    if eqpos
	      key=unescape(line[0..eqpos])
	      value=unescape(line[eqpos+2..-1])
	      @localehash[key]=value
	    else
	      raise "missing '=' in file #{@localefile} on line #{linenr}"
	    end
	  }
	}
      rescue Errno::ENOENT
	# no file found is not error
      end #begin
    end #if langname
  end
  def unescape(s)
    s.gsub(/\\#|\\\\|\\=|\\.../){ |substr|
      case substr[1]
      when ?# then '#'
      when ?= then '='
      when ?\\ then "\\"
      when ?x
	substr[2..3].hex.chr # FIXME: add error handling: return nil if invalid
      else
	substr[1..3].oct.chr # FIXME: add error handling: return nil if invalid
      end
    }
  end
  def escape(s)
    # awful backslashes :-(
    res=''
    s.gsub(%r{\\},"\\\\\\\\").gsub('#','\#').gsub('=','\=').each_byte {|x|
      x<?\s ? res << ("\\x%02x" % x): res << x.chr
    }
    res
  end
  def write_missing
    @write_missing=true
  end
  def translate(orig)
    res=@localehash.fetch(orig,nil)
    return res if res
#    puts '~~missing:'+orig
    if defined? @write_missing
      unless test('f',@localefile)
	File.open(@localefile,'w'){ |f| 
	  f.write <<EOT\
# Generated skeleton file for translation to #{@langname}
# quick reference for format of this file:
#  1, comment start with # not prefixed by backslash
#  2, line have format original=translated
#  3, sequences with special meaning: \\# is #, \\= is =
#     \\\\ is \\ \\000 is octal number (exactly 3 digits)
#     \\x00 is hexadecimal number (exactly 2 digits)
# you can generate original=original lines for yet untranslated text
# by calling JTLanguage.write_missing before text translation in source program
#
EOT
	}
      end
      unless defined? @stamp
	File.open(@localefile,'a'){ |f|
	  f.write "#\n#\n# UNTRANSLATED STRINGS WILL FOLLOW\n#generated at: "
	  f.write Time.new.to_s+' by '+(ENV['USER']||'unknown')+'@'+
	    (ENV['HOSTNAME']||'unknown')+"\n#\n"
	}
	@stamp=true
      end
      File.open(@localefile,'a'){ |f|
	eorig=escape(orig)
	f.write "#{eorig}=#{eorig}\n"
      }
      @localehash[orig]=orig
    end
    return orig
  end
  def localetranslation
    @localehash
  end
  def localename
    @langname
  end
end
