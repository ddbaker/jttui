#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#
# Jakub Travnik's textmode user interface
#

# language localization - example
$: << File.dirname(__FILE__)

require 'addlocalpath'
require 'jttui/jtloc'

JTLanguage.load_locale('./example-jtloc-lang')

strings=['Hello World!', 'Hello World!!', '#, \ and = characters']

# use this to generate translation file skeleton JTLanguage.write_missing

puts '----- Untranslated: -----'
strings.each{|s| puts s}
puts '----- Translated: -------'
strings.each{|s| puts -s}
