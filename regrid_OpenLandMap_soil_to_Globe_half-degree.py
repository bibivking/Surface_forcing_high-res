#!/usr/bin/env python

""" 
Raw soil data is from the Soil and Landscape Grid of Australia

http://www.clw.csiro.au/aclep/soilandlandscapegrid/GetData-DAP.html

We are using the Soil and Landscape Grid Australia-Wide 3D Soil Property Maps 
(3" resolution) - Release 1

We are degrading the 90m to 5km and moving it onto the matching AWAP grid using
a nearest neighbour interpolation.

After we are done I'm removing the raw (5 gig file to save space). Either 
re-download it or look on your black backup drive "raw_AUS_Soils"

By the way to just degrade the data gdalwarp -tr 0.05 -0.05 would do it.
"""
from osgeo import gdal, gdalconst
import sys
import glob
import os

__author__  = "Martin De Kauwe"
__version__ = "1.0 (09.07.2015)"
__email__   = "mdekauwe@gmail.com"

sys.path.append("../../../scripts")
from read_flt_file import ReadFltFile
from reproject_from_AUS_grid_to_lat_lon_grid import reproject_file

if __name__ == "__main__":
    
    fname = glob.glob("*.tif")[0]
    ofname = fname.split(".")[0] + "_5km_AWAP_grid.bin"
    
    F = ReadFltFile()
    
    file_to_match = "../../../AWAP_data/tmax/19500101_tmax.flt"
    F._read_met_header(file_to_match)
    ncols = F.meta['ncols']
    nrows = F.meta['nrows']
    
    reproject_file(fname, file_to_match, ofname)
    
    os.remove(fname)
    