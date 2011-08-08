#!/bin/sh

# convert inkscape files to laser-cutter suitable HPGL, using EPS as an
# intermediate format.  Display the output in a GUI window using hp2xx

# syntax:
# inkscape2cutterhpgl.sh somefile
# will convert somefile.svg to somefile.eps to somefile.plt

# currently set up for two colours (pens).  Scale factor of 1.4 seems to be
# required to rescale after EPS conversion: exactly 1.4 or sqrt(2)?
# Measured to be 1.40x and 1.41x

STEM=$1

# libreoffice draw, load Inkscape SVG, save as EPS
# pstoedit -f "hpgl:-pencolors 2" scan+bracket-take1.eps scan+bracket-take1.libreoffice.pstoedit.plt
# hp2xx -c23456 scan+bracket-take1.libreoffice.pstoedit.plt

inkscape --export-eps=$STEM.eps --export-area-drawing --without-gui $STEM.svg
pstoedit -f "hpgl:-pencolors 2" -xscale 1.4 -yscale 1.4 $STEM.eps $STEM.plt
hp2xx -c12 $STEM.plt &
hpgl2cutter.py "Laser Settings/Card2mm.SGX" $STEM.plt $STEM.pcl