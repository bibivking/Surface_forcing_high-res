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

def main( fn , fld , LAT , LON , level , unit , long_name , description):

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
    grid_lat, grid_lon = np.meshgrid(lat,lon)
    print(grid_lat)
    print(grid_lon)
    interpolate_to_5km_netcdf(fld , var , grid_lat, grid_lon , LAT , LON , level , unit , long_name , description)

    ds = None


def interpolate_to_5km_netcdf(fld , var , grid_lat, grid_lon , LAT , LON, level , unit , long_name , description):

    # create file and write global attributes
    out_fname = "%s_%s_AU_NAT_C.nc" %(fld, level)
    f = nc.Dataset(out_fname, 'w', format='NETCDF4')
    f.description = 'CSIRO Australia National Digital Soil Property Maps, created by MU Mengyuan'
    f.history = "Created by: %s" % (os.path.basename(__file__))
    f.creation_date = "%s" % (datetime.datetime.now())

    # set dimensions
    f.createDimension('lat', len(LAT))
    f.createDimension('lon', len(LON))
    f.Conventions = "CF-1.0"

    # create variables
    latitude = f.createVariable('lat', 'f4', ('lat',))
    latitude.long_name = "latitude"

    longitude = f.createVariable('lon', 'f4', ('lon',))
    longitude.long_name = "longitude"

    latitude[:] = LAT
    longitude[:] = LON

    Var = f.createVariable('%s' % fld, 'f4', ('lat','lon'))
    Var.units = unit
    Var.missing_value = -9999.
    Var.long_name = long_name
    Var.description = description

    Var = -9999.
    var[var == -9999.0] = np.nan
    abc = np.zeros((len(grid_lat[:,0]),len(grid_lat[0,:]),4), dtype=bool)

    for i in np.arange(0,len(LAT)):
        for j in np.arange(0,len(LON)):
            abc[:,:,0] = grid_lat[:,:] >= LAT[i]-0.025
            abc[:,:,1] = grid_lat[:,:] < LAT[i]+0.025
            abc[:,:,2] = grid_lon[:,:] >= LON[i]-0.025
            abc[:,:,3] = grid_lon[:,:] < LON[i]+0.025
            print(np.any(np.all(abc, axis=2)))
            if np.any(np.all(abc, axis=2)):
                Var[i,j] = np.nanmean(var[np.all(abc, axis=2)])
                print(var[a and b])
    f.close()

def plot_spitial(var,lon,lat):
    fig = plt.figure(figsize=[15,10])
    fig.subplots_adjust(hspace=0.1)
    fig.subplots_adjust(wspace=0.05)
    plt.rcParams['text.usetex'] = False
    plt.rcParams['font.family'] = "sans-serif"
    plt.rcParams['font.sans-serif'] = "Helvetica"
    plt.rcParams['axes.labelsize'] = 14
    plt.rcParams['font.size'] = 14
    plt.rcParams['legend.fontsize'] = 10
    plt.rcParams['xtick.labelsize'] = 14
    plt.rcParams['ytick.labelsize'] = 14


    almost_black = '#262626'
    # change the tick colors also to the almost black
    plt.rcParams['ytick.color'] = almost_black
    plt.rcParams['xtick.color'] = almost_black

    # change the text colors also to the almost black
    plt.rcParams['text.color'] = almost_black
    plt.rcParams['axes.edgecolor'] = almost_black
    plt.rcParams['axes.labelcolor'] = almost_black

    ax = fig.add_subplot(111)

    cmap = plt.cm.viridis_r

    img = ax.contourf(var, cmap=cmap, origin="upper")#, levels=levels)
    ax.set_xticks(lat)
    ax.set_yticks(lon)

    fig.savefig("tmp.png" , bbox_inches='tight', pad_inches=0.1)

if __name__ == "__main__":

    pyth    = '/srv/ccrc/data25/z5218916/data/CSIRO_soil'
    folder  = ['Bulk_density','Sand','Clay','Silt','Organic_C']

    # read AWAP latitude and longitude
    fcable = "/srv/ccrc/data25/z5218916/data/AWAP_to_netcdf/Wind/AWAP.Wind.3hr.2000.nc"
    cable = nc.Dataset(fcable, 'r')
    LAT   = pd.DataFrame(cable.variables['lat'][:], columns =['lat']).to_numpy().flatten()
    LON   = pd.DataFrame(cable.variables['lon'][:], columns =['lon']).to_numpy().flatten()
    fcable = None
    cable  = None
    print(LAT)
    print(LON)

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
            main(fn,fld,LAT,LON,level,unit,long_name,description)
