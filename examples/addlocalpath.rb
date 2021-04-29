# local library path module
# this module ensures that all examples try loading JTTui
# and related libraries from paths in JTTui source tree
#
# This allows to use examples without installing library
# and to develop new versions of library without afecting
# installed library.
# It is however requied to run configure and make.
#

#
# If the examples are installed, they should not include
# relative directories and following command should be
# commented out.
#

# add relatice path ../lib/ to search path
$:.unshift( File.join( '..', 'lib' ))

# add relatice path ../ to search path
$:.unshift( File.join( '..', '' ))
