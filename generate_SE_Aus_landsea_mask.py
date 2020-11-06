#!/usr/bin/env python

"""
Generate a land-sea mask so we just run the code on SE Aus.

That's all folks.
"""
__author__ = "Martin De Kauwe"
__version__ = "1.0 (30.09.2019)"
__email__ = "mdekauwe@gmail.com"

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import glob
import xarray as xr
import netCDF4 as nc
import datetime
import os
import sys
import shutil
import netCDF4

def main(in_fname, out_fname, openLand=False, csiro_fname=None):


    ds = xr.open_dataset(in_fname)

    ds_out = ds.copy()

    landsea = ds.landsea.values
    #landsea = np.where(np.logical_and(
    #                      ((ds_out.lat <= -28.0) & (ds_out.lat >= -40.0) &
    #                       (ds_out.lon >= 140.0) & (ds_out.lon <= 154.0)),
    #                      landsea == 0.0),
    #                      0.0, 1.0)
    landsea = np.where(np.logical_and(
                          ((ds_out.latitude <= -28.0) & (ds_out.latitude >= -40.0) &
                           (ds_out.longitude >= 140.0) & (ds_out.longitude <= 154.0)),
                          landsea == 0.0),
                          0.0, 1.0)

    # mask by CSIRO sea too...we seem to have a few bad coastal pixels in the
    # openland mask file.
    if openLand:
        ds_csiro = xr.open_dataset(csiro_fname)
        landsea_csiro = ds_csiro.landsea.values
        landsea = np.where(landsea_csiro == 1.0, 1.0, landsea)


    ds_out['landsea'][:,:] = landsea

    ds_out.to_netcdf(out_fname)
    ds_out.close()

if __name__ == "__main__":

    in_fname  = "gridinfo_AWAP_OpenLandMap_DLCM_mask.nc"
    out_fname = "SE_AUS_gridinfo_AWAP_OpenLandMap_DLCM_mask.nc"
    main(in_fname, out_fname)

    # in_fname = "gridinfo_AWAP_OpenLandMap_DLCM_mask.nc"
    # out_fname = "SE_AUS_gridinfo_AWAP_OpenLandMap_DLCM_mask.nc"
    # main(in_fname, out_fname, openLand=True,
    #      csiro_fname="mask/SE_AUS_AWAP_csiro_soil_landmask.nc")
