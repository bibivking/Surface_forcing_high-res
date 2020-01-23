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

import os
import sys
import glob
import gdal
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.colors
import netCDF4 as nc
import datetime
import pandas as pd

def main( fn , fld , level , unit , long_name , description):

    ds = gdal.Open(fn, gdal.GA_ReadOnly)
    rb = ds.GetRasterBand(1)
    var = rb.ReadAsArray()

    transf = ds.GetGeoTransform()
    cols = ds.RasterXSize # 49200
    rows = ds.RasterYSize # 40800
    #bands = ds.RasterCount
    #bandtype = gdal.GetDataTypeName(var.DataType) #Int16
    #driver = ds.GetDriver().LongName #'GeoTIFF'
    print(transf)
    lon = np.arange(transf[0],transf[0]+cols*transf[1],transf[1])
    lat = np.arange(transf[3]+(rows-1)*transf[5],transf[3]-transf[5],-transf[5])

    print(lon)
    print(lat)
    #plot_spitial(var,lon,lat)
    interpolate_to_netcdf(fld , var , lat, lon , level , unit , long_name , description)

    ds = None


def interpolate_to_netcdf(fld , var , lat, lon , level , unit , long_name , description):

    # create file and write global attributes
    out_fname = "%s_%s_AU_NAT_C.nc" %(fld, level)
    f = nc.Dataset(out_fname, 'w', format='NETCDF4')
    f.description = 'CSIRO Australia National Digital Soil Property Maps, created by MU Mengyuan'
    f.history = "Created by: %s" % (os.path.basename(__file__))
    f.creation_date = "%s" % (datetime.datetime.now())

    # set dimensions
    f.createDimension('lat', len(lat))
    f.createDimension('lon', len(lon))
    f.Conventions = "CF-1.0"

    # create variables
    latitude = f.createVariable('lat', 'f4', ('lat',))
    latitude.long_name = "latitude"

    longitude = f.createVariable('lon', 'f4', ('lon',))
    longitude.long_name = "longitude"

    latitude[:] = lat
    longitude[:] = lon

    Var = f.createVariable('%s' % fld, 'f4', ('lat','lon'))
    Var.units = unit
    Var.missing_value = -9999.
    Var.long_name = long_name
    Var.description = description
    Var[:,:] = var[::-1,:]
    f.close()


if __name__ == "__main__":

    pyth    = '/srv/ccrc/data25/z5218916/data/CSIRO_soil'
    folder  = ['Bulk_density','Sand','Clay','Silt','Organic_C']

    for fld in folder:
        if fld == 'Bulk_density':
            unit = "g/cm3"
            long_name = "Bulk Density (whole earth)"
            description = "Bulk Density of the whole soil (including coarse fragments) in mass per unit volume by a method equivalent to the core method"
        elif fld == 'Sand':
            unit = "%"
            long_name = "sand"
            description = "20 um - 2 mm mass fraction of the < 2 mm soil material determined using the pipette method"
        elif fld == 'Clay':
            unit = "%"
            long_name = "clay"
            description = "< 2 um mass fraction of the < 2 mm soil material determined using the pipette method"
        elif fld == 'Silt':
            unit = "%"
            long_name = "silt"
            description = "2-20 um mass fraction of the < 2 mm soil material determined using the pipette method"
        elif fld == 'Organic_C':
            unit = "%"
            long_name = "Organic Carbon"
            description = "Mass fraction of carbon by weight in the < 2 mm soil material as determined by dry combustion at 900 Celcius"

        pyth_full = os.path.join(pyth, "%s" % (fld))
        file_list = glob.glob(os.path.join(pyth_full, "*.tif"))

        for fn in file_list:
            level = "%s-%s" %(os.path.basename(fn).split("/")[-1].split("_")[1],os.path.basename(fn).split("/")[-1].split("_")[2])
            print(level)
            main(fn,fld,level,unit,long_name,description)
