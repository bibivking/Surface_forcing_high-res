#!/usr/bin/env python
__author__    = "MU Mengyuan"

import os
import sys
import glob
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.colors
import netCDF4 as nc
from matplotlib import cm
from matplotlib import ticker
import xarray as xr

fig = plt.figure(figsize=[13,17.5])
fig.subplots_adjust(hspace=0.1)
fig.subplots_adjust(wspace=0.1)

plt.rcParams['text.usetex']     = False
plt.rcParams['font.family']     = "sans-serif"
plt.rcParams['font.serif']      = "Helvetica"
plt.rcParams['axes.linewidth']  = 1.5
plt.rcParams['axes.labelsize']  = 14
plt.rcParams['font.size']       = 14
plt.rcParams['legend.fontsize'] = 12
plt.rcParams['xtick.labelsize'] = 14
plt.rcParams['ytick.labelsize'] = 14

ax1  = fig.add_subplot(511)
ax2  = fig.add_subplot(512)
ax3  = fig.add_subplot(513)
ax4  = fig.add_subplot(514)
ax5  = fig.add_subplot(515)

cmap1 = plt.cm.terrain #hsv #gist_ncar #RdBu
cmap2 = plt.cm.Spectral

# tangent slope

fname = "/srv/ccrc/data45/z3509830/CABLE_runs/CABLE_testing/slope_data/GTOPO30_slope_in_tangent_4neighbours.nc"
w     = xr.open_dataset(fname)

slope_in_m_m_0 = w.slope
slope_in_m_m_0 = np.where(np.isnan(slope_in_m_m_0), np.nan, slope_in_m_m_0)

slope_tangent = np.zeros((15000,36000))
slope_tangent[:,0:18000]     = slope_in_m_m_0[:,18000:36000]
slope_tangent[:,18000:36000] = slope_in_m_m_0[:,0:18000]

# degree slope

fname1 = "/srv/ccrc/data45/z3509830/CABLE_runs/CABLE_testing/slope_data/GTOPO30_slope_in_degrees.nc"
x     = xr.open_dataset(fname1)

vertical = 1000 * np.tan(np.radians(x.slope))
slope_in_m_m_1 = vertical / 1000.
slope_in_m_m_1 = np.tan(np.radians(x.slope))
slope_in_m_m_1 = np.where(np.isnan(slope_in_m_m_1), np.nan, slope_in_m_m_1)

slope_degree                = np.zeros((15000,36000))
slope_degree[:,0:18000]     = slope_in_m_m_1[:,18000:36000]
slope_degree[:,18000:36000] = slope_in_m_m_1[:,0:18000]

# slope_in_m_m_2 = np.tan(np.radians(x.slope))
# slope_in_m_m_2 = np.where(np.isnan(slope_in_m_m_2), np.nan, slope_in_m_m_2)
#
# slope_new                = np.zeros((15000,36000))
# slope_new[:,0:18000]     = slope_in_m_m_2[:,18000:36000]
# slope_new[:,18000:36000] = slope_in_m_m_2[:,0:18000]

slope_calc = np.zeros((300,720))
for lat in np.arange(0,300,1):
    for lon in np.arange(0,720,1):
        slope_calc[lat,lon] = np.average(slope_degree[lat*50:lat*50+50,lon*50:lon*50+50])

# Mark's
fname2 = "/srv/ccrc/data25/z5218916/cable/src/CABLE-AUX/offline/gridinfo_mmy_MD_elev_orig_std_avg-sand_mask.nc"
y = xr.open_dataset(fname2)

slope_mark = y.slope
slope_mark = np.flipud(slope_mark)

# CLM
fname3 = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/surfdata_360x720cru_16pfts__CMIP6_simyr2000_c170616.nc"
z = xr.open_dataset(fname3)

slope_clm = np.tan(np.radians(z.SLOPE))
slope_clm = np.where(np.isnan(slope_clm), np.nan, slope_clm)
slope_clm = np.flipud(slope_clm)


# plot
img1 = ax1.imshow(slope_tangent[10000:13500,11000:16000],cmap=cmap1, vmin=0, vmax=0.3)
# img2 = ax2.imshow(slope_degree[10000:13500,11000:16000],cmap=cmap1, vmin=0, vmax=0.4)
img2 = ax2.imshow(slope_calc[200:270,220:320],cmap=cmap1, vmin=0, vmax=0.3)
# img3 = ax3.imshow(slope_mark[200:270,220:320], cmap=cmap1, vmin=0, vmax=0.3)

img3 = ax3.imshow(slope_mark[200:270,220:320]-slope_clm[200:270,220:320], cmap=cmap2, vmin=-0.1, vmax=0.1)
img4 = ax4.imshow(slope_calc[200:270,220:320]-slope_clm[200:270,220:320], cmap=cmap2, vmin=-0.1, vmax=0.1)
img5 = ax5.imshow(slope_calc[200:270,220:320]-slope_mark[200:270,220:320], cmap=cmap2, vmin=-0.1, vmax=0.1)

cbar1 = fig.colorbar(img1, ax = ax1,  orientation="vertical", pad=0.02, shrink=.6)
cbar1.set_label('tangent slope')
cbar1.update_ticks()

cbar2 = fig.colorbar(img2, ax = ax2,  orientation="vertical", pad=0.02, shrink=.6)
cbar2.set_label('degree2tangent slope')
cbar2.update_ticks()

cbar3 = fig.colorbar(img3, ax = ax3,  orientation="vertical", pad=0.02, shrink=.6)
cbar3.set_label("Mark - CLM")
cbar3.update_ticks()

cbar4 = fig.colorbar(img4, ax = ax4,  orientation="vertical", pad=0.02, shrink=.6)
cbar4.set_label("ours - CLM")
cbar4.update_ticks()

cbar5 = fig.colorbar(img5, ax = ax5,  orientation="vertical", pad=0.02, shrink=.6)
cbar5.set_label("ours - Mark")
cbar5.update_ticks()

fig.savefig("./slope_comp.png", bbox_inches='tight', pad_inches=0.1)
