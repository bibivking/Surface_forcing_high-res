;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

; Changed from 2-Dec-2019
; This script (converge_grid_elev_for_AWAP.ncl) is changed from converge_grid_elev_std_opt_mask_sand+sand2.ncl
; and AU_gridinfo_AWAP.ncl

;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________

begin

fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/gridinfo_AWAP_CSIRO_AU_NAT.nc"
finout  = addfile (fname_inout, "w")     ; open output file

fname_grid = "/srv/ccrc/data45/z3509830/CABLE_runs/CABLE_site_runs/CABLE_AUX-dev/offline/CABLE_UNSW_GSWP3_gridinfo_0.5x0.5_site.nc"
                 ;lat from + to - lon from -180 to 180
fgrid      = addfile (fname_grid,"r")

fname_LAI  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/lai_climatology_AWAP_grid.nc"
fLAI  = addfile(fname_LAI, "r")

; _________________ set range of lat and lon ______________________
lat_s = -44.
lat_e = -10.
lon_s = 112.
lon_e = 154.

nlat   = 681
nlon   = 841
ntime  = 12
nsoil  = 6
npatch = 1
nrad   = 3
nsdepth = 6

soil_depth= (/0.011,0.051,0.157,0.4385,1.1855,3.164/)
latitude  = fspan( lat_s, lat_e, nlat)
longitude = fspan( lon_s, lon_e, nlon)
; ----------------- 3D --------------------

; =======  LAI  ========
; use Mark's gridinfo file to fill default value in Martin's LAI file
filevardef( finout, "LAI", "float", (/"time", "latitude", "longitude" /))

;LAI   = new((/ntime, nlat, nlon/),  "float")
;LAI!0 = "latitude"
;LAI!1 = "longitude"
;LAI&latitude  = fspan( lat_s, lat_e, nlat)
;LAI&longitude = fspan( lon_s, lon_e, nlon)
LAI = fLAI->LAI
lai = new((/ntime, nlat, nlon/),  float)

do x = lat_s+0.25,lat_e-0.25,0.5
  do y = lon_s+0.25,lon_e-0.25,0.5
    do time = 0, 11
       lai(time,{x-0.25:x+0.25},{y-0.25:y+0.25}) = fgrid->LAI(time,{x},{y}))
    end do
  end do
end do

LAI = where(ismissing(LAI),lai,LAI)
finout->LAI@long_name     = "Leaf area index"
finout->LAI@_FillValue    = -9999. ; set -9999. because no missing value point in gridinfo
finout->LAI               = LAI*1.0
delete(LAI)
delete(lai)

; =======  SOIL  ========
rhosoil_temp = new((/nsdepth, nlat, nlon/), float)
sand_temp    = new((/nsdepth, nlat, nlon/), float)
clay_temp    = new((/nsdepth, nlat, nlon/), float)
silt_temp    = new((/nsdepth, nlat, nlon/), float)
organic_temp = new((/nsdepth, nlat, nlon/), float)

level_class = (/"000_005","005_015","015_030","030_060","060_100","100_200"/)

do level = 0,5
    frho  = addfile("Bulk_density_"+level_class(level)+"_AU_NAT_C.nc", "r")
    fsand = addfile("Sand_"+level_class(level)+"_AU_NAT_C.nc", "r")
    fclay = addfile("Clay_"+level_class(level)+"_AU_NAT_C.nc", "r")
    fsilt = addfile("Silt_"+level_class(level)+"_AU_NAT_C.nc", "r")
    forg  = addfile("Organic_C_"+level_class(level)+"_AU_NAT_C.nc", "r")

    rhosoil_temp(level,:,:) = frho->Bulk_density*1000. ; g/cm3 -> kg/m3
    sand_temp(level,:,:)    = fsand->Sand/100.         ; % -> m3/m3
    clay_temp(level,:,:)    = fclay->Clay/100.
    silt_temp(level,:,:)    = fsilt->Silt/100.
    organic_temp(level,:,:) = forg->Organic_C/100.
end do

rhosoil_vec = new((/nsdepth, nlat, nlon/), float)
sand_vec    = new((/nsdepth, nlat, nlon/), float)
clay_vec    = new((/nsdepth, nlat, nlon/), float)
silt_vec    = new((/nsdepth, nlat, nlon/), float)
organic_vec = new((/nsdepth, nlat, nlon/), float)
hyds_vec    = new((/nsdepth, nlat, nlon/), float)
bch_vec     = new((/nsdepth, nlat, nlon/), float)
sucs_vec    = new((/nsdepth, nlat, nlon/), float)
ssat_vec    = new((/nsdepth, nlat, nlon/), float)
swilt_vec   = new((/nsdepth, nlat, nlon/), float)
sfc_vec     = new((/nsdepth, nlat, nlon/), float)
css_vec     = new((/nsdepth, nlat, nlon/), float)
watr        = new((/nsdepth, nlat, nlon/), float)
cnsd        = new((/nsdepth, nlat, nlon/), float)

rhosoil_vec(0,:,:) = rhosoil_temp(0,:,:)
sand_vec(0,:,:)    = sand_temp(0,:,:)
clay_vec(0,:,:)    = clay_temp(0,:,:)
silt_vec(0,:,:)    = silt_temp(0,:,:)
organic_vec(0,:,:) = organic_temp(0,:,:)

rhosoil_vec(1,:,:) = (rhosoil_temp(0,:,:)*0.028 + rhosoil_temp(1,:,:)*0.03)/0.058
sand_vec(1,:,:)    = (sand_temp(0,:,:)*0.028 + sand_temp(1,:,:)*0.03)/0.058
clay_vec(1,:,:)    = (clay_temp(0,:,:)*0.028 + clay_temp(1,:,:)*0.03)/0.058
silt_vec(1,:,:)    = (silt_temp(0,:,:)*0.028 + silt_temp(1,:,:)*0.03)/0.058
organic_vec(1,:,:) = (organic_temp(0,:,:)*0.028 + organic_temp(1,:,:)*0.03)/0.058

rhosoil_vec(2,:,:) = (rhosoil_temp(1,:,:)*0.07 + rhosoil_temp(2,:,:)*0.084)/0.154
sand_vec(2,:,:)    = (sand_temp(1,:,:)*0.07 + sand_temp(2,:,:)*0.084)/0.154
clay_vec(2,:,:)    = (clay_temp(1,:,:)*0.07 + clay_temp(2,:,:)*0.084)/0.154
silt_vec(2,:,:)    = (silt_temp(1,:,:)*0.07 + silt_temp(2,:,:)*0.084)/0.154
organic_vec(2,:,:) = (organic_temp(1,:,:)*0.07 + organic_temp(2,:,:)*0.084)/0.154

rhosoil_vec(3,:,:) = (rhosoil_temp(2,:,:)*0.066 + rhosoil_temp(3,:,:)*0.3 + rhosoil_temp(4,:,:)*0.043)/0.409
sand_vec(3,:,:)    = (sand_temp(2,:,:)*0.066 + sand_temp(3,:,:)*0.3 + sand_temp(4,:,:)*0.043)/0.409
clay_vec(3,:,:)    = (clay_temp(2,:,:)*0.066 + clay_temp(3,:,:)*0.3 + clay_temp(4,:,:)*0.043)/0.409
silt_vec(3,:,:)    = (silt_temp(2,:,:)*0.066 + silt_temp(3,:,:)*0.3 + silt_temp(4,:,:)*0.043)/0.409
organic_vec(3,:,:) = (organic_temp(2,:,:)*0.066 + organic_temp(3,:,:)*0.3 + organic_temp(4,:,:)*0.043)/0.409

rhosoil_vec(4,:,:) = (rhosoil_temp(4,:,:)*0.357 + rhosoil_temp(4,:,:)*0.728)/1.085
sand_vec(4,:,:)    = (sand_temp(4,:,:)*0.357 + sand_temp(4,:,:)*0.728)/1.085
clay_vec(4,:,:)    = (clay_temp(4,:,:)*0.357 + clay_temp(4,:,:)*0.728)/1.085
silt_vec(4,:,:)    = (silt_temp(4,:,:)*0.357 + silt_temp(4,:,:)*0.728)/1.085
organic_vec(4,:,:) = (organic_temp(4,:,:)*0.357 + organic_temp(4,:,:)*0.728)/1.085

rhosoil_vec(5,:,:) = rhosoil_temp(5,:,:)
sand_vec(5,:,:)    = sand_temp(5,:,:)
clay_vec(5,:,:)    = clay_temp(5,:,:)
silt_vec(5,:,:)    = silt_temp(5,:,:)
organic_vec(5,:,:) = organic_temp(5,:,:)

; ________________________________ Mark Decker's equations for elev file ___________________________________
; From /g/data1/w35/mrd561/CABLE2_runs/CMIP6-GM2-testing/ssgw_Feb23.2018/opt/surface_data/add_derived_SWC.py

hyds_vec = (1.0-organic_vec) * 0.00706 * ( 10.0 ^ (-0.60 + 1.26*sand_vec - 0.64*clay_vec) ) + organic_vec*10^(-4)
bch_vec  = (1.0-organic_vec) * ( 3.1 + 15.7*clay_vec - 0.3*sand_vec ) + organic_vec*3.0
sucs_vec = (1.0-organic_vec) * 10.0 * 10.0^( 1.54 - 0.95*sand_vec + 0.63*silt_vec ) + organic_vec*10.3
ssat_vec = (1.0-organic_vec) * ( 0.505 - 0.142*sand_vec - 0.037*clay_vec ) + organic_vec*0.6
watr     = (1.0-organic_vec) * ( 0.02 + 0.018*clay_vec ) + organic_vec*0.15

sst_tmp = ssat_vec
sst_tmp = where(sst_tmp .gt. 0.85, 0.85, sst_tmp)
sst_tmp = where(sst_tmp .lt. 0.15, 0.15, sst_tmp)
sst_tmp = 1.0 - sst_tmp

iveg    = finout->iveg

psi_tmp = ssat
psi_tmp = 2750000.
psi_tmp = where( iveg .le. 3, 2550000.0, psi_tmp)
psi_tmp = where( iveg .eq. 4, 2240000.0, psi_tmp)
psi_tmp = where( iveg .eq. 5, 4280000.0, psi_tmp)
do level = 0,5
    swilt_vec(level,:,:) = (ssat_vec(level,:,:) - watr(level,:,:)) \
                          * ((psi_tmp/sucs_vec(level,:,:)) ^ (-1.0/bch_vec(level,:,:)))\
                          + watr(level,:,:)
end do
sfc_vec  = (ssat_vec - watr) * ( 1.157407 * 10^(-06) / hyds_vec) ^ (1.0 / (2.0*bch_vec + 3.0) ) + watr
css  = (1.0-organic_vec) * ( 850*(1.0 - sand_vec - clay_vec) + 865.0*clay_vec + 750.0*sand_vec ) + organic_vec*950.0
cnsd = (1.0-organic_vec) * ( 0.135*sst_tmp + 0.0239/sst_tmp )  / (1.0 - 0.947*sst_tmp) + organic_vec*0.05

; __________________ Note that ! ___________________
; Below are the soil properties for fully organic soil in
; ./Marks_latest_branch_with_fixes/core/biogeophys/cable_common.F90
; They are different from these parameters used in this script!
;        hyds_vec = 1.0e-4,&
;        sucs_vec = 10.3,   &
;        bch_vec  = 2.91,     &
;        ssat_vec = 0.9,    &
;        watr     = 0.1,&
;        css_vec  = 4000.0,&
;        cnsd_vec = 0.1

var_name = (/ "rhosoil_vec", "sand_vec", "clay_vec", "silt_vec", "org_vec", "bch_vec",\
              "sucs_vec", "ssat_vec", "sfc_vec", "css_vec", "cnsd_vec", "hyds_vec",\
              "watr", "cnsd" /)

do var_num = 0,dimsizes(var_name)-1
    filevardef(finout, var_name(var_num), "float", (/ "soil_depth", "latitude", "longitude" /))
    finout->$var_name(var_num)$@_FillValue  = -9999.
    finout->$var_name(var_num)$!0 = "soil_depth"
    finout->$var_name(var_num)$!1 = "latitude"
    finout->$var_name(var_num)$!2 = "longitude"
    finout->$var_name(var_num)$&soil_depth = soil_depth
    finout->$var_name(var_num)$&latitude   = latitude
    finout->$var_name(var_num)$&longitude  = longitude
    finout->$var_name(var_num)$@_FillValue = -9999.
end do

finout->rhosoil_vec = rhosoil_vec*1.
finout->sand_vec    = sand_vec*1.
finout->clay_vec    = clay_vec*1.
finout->silt_vec    = silt_vec*1.
finout->org_vec     = organic_vec*1.
finout->hyds_vec    = hyds_vec*1.
finout->bch_vec     = bch_vec*1.
finout->sucs_vec    = sucs_vec*(-1.0)/1000. ; sucs should be positive value?? or negetive value?
finout->ssat_vec    = ssat_vec*1.
finout->swilt_vec   = swilt_vec*1.
finout->sfc_vec     = sfc_vec*1.
finout->css_vec     = css_vec*1.
finout->watr        = watr*1.
finout->cnsd        = cnsd*1.

finout->rhosoil_vec@long_name = "Soil bulk density"
finout->rhosoil_vec@units     = "kg/m3"
finout->sand_vec@long_name    = "Sand fraction"
finout->sand_vec@units        = "m3/m3"
finout->clay_vec@long_name    = "Clay fraction"
finout->clay_vec@units        = "m3/m3"
finout->silt_vec@long_name    = "Silt fraction"
finout->silt_vec@units        = "m3/m3"
finout->org_vec@long_name     = "Organic carbon fraction"
finout->org_vec@units         = "m3/m3"
finout->hyds_vec@long_name    = "saturated soil conductivity"
finout->hyds_vec@units        = "mm/s"
finout->bch_vec@long_name     = "Clapp-Hornberger b coefficient"
finout->sucs_vec@long_name    = "Saturated soil water suction"
finout->sucs_vec@units        = "m" ; check it with original equation
finout->ssat_vec@long_name    = "Volumetric soil moisture content at saturation"
finout->ssat_vec@units        = "m3/m3"
finout->swilt_vec@long_name   = "Volumetric soil moisture content at wilting point"
finout->swilt_vec@units       = "m3/m3"
finout->sfc_vec@long_name     = "Field capacity (volumetric soil moisture content at critical point)" ;
finout->sfc_vec@units         = "m3/m3"
finout->css_vec@long_name     = "Soil specific heat capacity" ;
finout->css_vec@units         = "J/kg/K" ;
finout->cnsd@long_name        = "Thermal conductivity"
finout->cnsd@units            = "W/m/K" ;
finout->watr@long_name        = "Residual water content of the soil"
finout->watr@units            = "m3/m3"




; ----------------- 2D --------------------
filevardef( finout, "rhosoil", "float", (/ "latitude", "longitude" /))
filevardef( finout, "sand", "float", (/ "latitude", "longitude" /))
filevardef( finout, "silt", "float", (/ "latitude", "longitude" /))
filevardef( finout, "clay", "float", (/ "latitude", "longitude" /))
filevardef( finout, "organic", "float", (/ "latitude", "longitude" /))

filevardef( finout, "hyds", "float", (/ "latitude", "longitude" /))
filevardef( finout, "bch", "float", (/ "latitude", "longitude" /))
filevardef( finout, "sfc", "float", (/ "latitude", "longitude" /))
filevardef( finout, "ssat", "float", (/ "latitude", "longitude" /))
filevardef( finout, "sucs", "float", (/ "latitude", "longitude" /))
filevardef( finout, "swilt", "float", (/ "latitude", "longitude" /))
filevardef( finout, "css", "float", (/ "latitude", "longitude" /))
filevardef( finout, "cnsd", "float", (/ "latitude", "longitude" /))




filevardef( finout, "isoil", "integer", (/ "latitude", "longitude" /)) ; Need to be calculated

finout->isoil@long_name     = "Zobler soil type";
finout->isoil@missing_value = -1

; ----------------- 3D --------------------

fout->hyds   = hyds/1000.
fout->sucs   = sucs*(-1.0)/1000.



end
