#!/bin/bash
#-
# SPDX-License-Identifier: BSD-2-Clause
#
# Copyright (c) 2011-2013 A. Theodore Markettos
#
# This software was developed by the University of Cambridge Computer
# Laboratory under EPSRC contract EP/G015783/1, as part of the
# Biologically-Inspired Massively Parallel Architectures (BIMPA) research
# project.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

# convert inkscape files to laser-cutter suitable HPGL, using EPS as an
# intermediate format.  Display the output in a GUI window using hp2xx

# syntax:
# inkscape2cutterhpgl.sh somefile
# will convert somefile.svg to somefile.eps to somefile.plt

# also
# inkscape2cutterhpgl.sh somefile Acrylic4mm.SGX
# will search the 

# requires pstoedit 3.60 or later, with drvhpgl.pencolors file created from:
#  echo -e "0 1.0 1.0 1.0\n1 0.0 0.0 0.0\n2 1.0 0.0 0.0\n3 0.0 1.0 0.0\n4 1.0 1.0 0.0\n5 0.0 0.0 1.0\n6 1.0 0.0 1.0\n7 0.0 1.0 1.0\n" > drvhpgl.pencolors"
# placed in pstoedit's data directory (eg /usr/share/pstoedit/)

# currently set up for two colours (pens).  Scale factor of 1.4 seems to be
# required to rescale after EPS conversion: exactly 1.4 or sqrt(2)?
# Measured to be between 1.40x and 1.41x (ie not 1.414)
set -e

DEFAULT_MATERIAL=Card2mm.SGX
PSTOEDIT=pstoedit
INKSCAPE=inkscape
HP2XX=hp2xx
HP2XX_WIN=/usr/local/lib/hpglview/hpglview.exe

STEM=$1
if [[ -z $1 ]] ; then
  echo "Syntax: inkscape2cutterhpgl.sh svgfile [material file]"
  echo "(filename provided without extension)"
  echo "material file also searched for in Laser Settings directory"
  echo "Default material: $DEFAULT_MATERIAL"
  exit
fi

if [[ ! -z "$2" ]]; then
  if [ -f "$2" ]; then
    MATERIAL_FILE=$2
  else
    MATERIAL_FILE="$( cd "$( dirname "$0" )/laser-settings" && readlink -f $2 )"
    if [[ ! -f $MATERIAL_FILE ]]; then
      echo "Material file $MATERIAL_FILE not found (also searched Laser Settings directory)"
      exit
    fi
  fi
fi

if [ -z "$MATERIAL_FILE" ]; then
  MATERIAL_FILE="$( dirname "$0" )/Laser Settings/$DEFAULT_MATERIAL"
fi

hash $PSTOEDIT 2>&- || { echo >&2 \
  "****** ERROR ******: pstoedit version 3.6 or later is required for conversion." \
  "Download from http://www.pstoedit.net/ and build with libplot enabled"; exit 1; }


PSTOEDIT_VERSION=`$PSTOEDIT --help 2>&1 | grep -m1 version | cut -c 19-22`
PSTOEDIT_NEW_ENOUGH=$(echo $PSTOEDIT_VERSION " > 3.59" | bc)
echo $PSTOEDIT_VERSION $PSTOEDIT_NEW_ENOUGH
if [ $PSTOEDIT_NEW_ENOUGH -ne 1 ]; then
  echo "****** WARNING ******"
  echo "For correct laser power selection you need to install"
  echo "pstoedit version 3.60 or later from"
  echo "http://www.pstoedit.net/"
  echo "with libplot enabled.  (Found version $PSTOEDIT_VERSION)."
  echo "then do:"
  echo "echo -e \"0 1.0 1.0 1.0\n1 0.0 0.0 0.0\n2 1.0 0.0 0.0\n3 0.0 1.0 0.0\n4 1.0 1.0 0.0\n5 0.0 0.0 1.0\n6 1.0 0.0 1.0\n7 0.0 1.0 1.0\n\" > drvhpgl.pencolors"
  echo "and put that file in pstoedit's data directory (eg /usr/share/pstoedit/)"
  echo "Continuing anyway..."
  echo "***** END WARNING *****"
fi


hash $HP2XX 2>&- || { echo >&2 "****** WARNING ******: hp2xx is required for previewing plots - continuing anyway"; }

# libreoffice draw, load Inkscape SVG, save as EPS
# pstoedit -f "hpgl:-pencolors 2" scan+bracket-take1.eps scan+bracket-take1.libreoffice.pstoedit.plt
# hp2xx -c23456 scan+bracket-take1.libreoffice.pstoedit.plt

SCRIPT_PARENT="$( cd "$( dirname "$0" )" && pwd )"
#echo $SCRIPT_PARENT
#SCRIPT_PARENT_WIN=`cygpath -w $SCRIPT_PARENT`
SCRIPT_PARENT_WIN="$SCRIPT_PARENT"
#echo $SCRIPT_PARENT_WIN
#export PYTHONPATH=$SCRIPT_PARENT_WIN/Chiplotle-0.3.0-py2.7.egg:$PYTHON_PATH
PYTHON=python
# create directory for chiplotle logfile
mkdir -p ~/.chiplotle

#MATERIAL_FILE_WIN=`cygpath -w $MATERIAL_FILE`
MATERIAL_FILE_WIN="$MATERIAL_FILE"
#HP2XX="cygstart $HP2XX_WIN"
#HP2XX="$HP2XX -c1237465"
HP2XX="hp2xx"

# calibrated from test runs
#XSCALE=1.41
#YSCALE=1.41
XSCALE=1.0
YSCALE=1.0
#echo $SCRIPT_PARENT
echo "Using material $MATERIAL_FILE_WIN"
#exit
$INKSCAPE --export-eps=$STEM.eps --export-area-page --export-text-to-path --without-gui $STEM.svg
# using modified pstoedit 3.50 with -pencolortable patch
#$PSTOEDIT -f "hpgl:-pencolors 7 -pencolortable \"#000000,#ff0000,#00ff00,#ffff00,#0000ff,#ff00ff,#00ffff\"" -xscale $XSCALE -yscale $YSCALE $STEM.eps $STEM.plt
# using vanilla pstoedit 3.60 - needs a drvhpgl.pencolors file in pstoedit's data directory
$PSTOEDIT -f "hpgl:-pencolorsfromfile" -xscale $XSCALE -yscale $YSCALE $STEM.eps $STEM.plt
$PYTHON $SCRIPT_PARENT_WIN/tidyhpgl4cutter.py $STEM.plt $STEM.clean.plt
# display a simulated plot - map hp2xx pen colours to default Spirit GX colours
# (actually we should parse the .SGX file to extract the RGB colours)
$HP2XX $STEM.clean.plt &
$PYTHON $SCRIPT_PARENT_WIN/hpgl2cutter.py "$MATERIAL_FILE_WIN" $STEM.clean.plt $STEM.clean.pcl
#hpgl2cutter.py "Laser Settings/Arcmm.SGX" $STEM.plt $STEM.pcl

if [ $PSTOEDIT_NEW_ENOUGH -ne 1 ]; then
  echo "REPEAT WARNING: laser power settings incorrect due to out-of-date pstoedit (see above)"
fi


# TODO
# Automatic Windows/Linux switching
# Pen colours (pstoedit, hpglviewer)
# Shiny GUI
