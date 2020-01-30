;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

; __________________________________ MMY _______________________________________
; Purpose: regrid LAI data,
;          read soil texture data,
;          calculate soil hydraulic parameters
;          form gridinfo data
; ______________________________________________________________________________

;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 500000000000 ;
end setvalues
;_____________________________________

begin

; _________________ option __________________
  soil_data_type = 0 ; 0: CSIRO, 1: OpenLandMap

; ________________ file name ________________
if soil_data_type .eq. 0 then
    fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_CSIRO_AU_NAT.nc"
    finout  = addfile (fname_inout, "r")     ; open output file
else if soil_data_type .eq. 1 then
    fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_OpenLandMap.nc"
    finout  = addfile (fname_inout, "r")     ; open output file
end if
end if

fname_grid = "/srv/ccrc/data45/z3509830/CABLE_runs/CABLE_site_runs/CABLE_AUX-dev/offline/CABLE_UNSW_GSWP3_gridinfo_0.5x0.5_site.nc"
                 ;lat from + to - lon from -180 to 180
fgrid      = addfile (fname_grid,"r")

;fname_LAI  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/lai_climatology_AWAP_grid.nc" ; Gimms
fname_LAI  = "/srv/ccrc/data04/z3509830/Fluxnet_data/All_flux_sites_processed/Copernicus_LAI_time_series/Aus/monthly_climatology.nc" ; Anna's Copernicus
fLAI       = addfile(fname_LAI, "r")

; _________________________ Check Value ____________________________
pic = "check_value"
wks = gsn_open_wks("pdf",pic)
gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")
res            = True
res@cnFillMode = "RasterFill"            ; Raster Mode
res@cnFillOn   = True
res@cnLinesOn  = False

print("a")
res@txString = "LAI"
plot = gsn_csm_contour(wks, fLAI->LAI(0,:,:),res)
plot = gsn_csm_contour(wks,finout->LAI(0,:,:),res)
print("b")
; read soil texture nc file
;level_class = (/"000-005","005-015","015-030","030-060","060-100","100-200"/)

;level = 0
;print(level_class(level))
;frho  = addfile("/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/Bulk_density_"+level_class(level)+"_AU_NAT_C.nc", "r")
;fsand = addfile("/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/Sand_"+level_class(level)+"_AU_NAT_C.nc", "r")
;fclay = addfile("/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/Clay_"+level_class(level)+"_AU_NAT_C.nc", "r")
;fsilt = addfile("/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/Silt_"+level_class(level)+"_AU_NAT_C.nc", "r")
;forg  = addfile("/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/Organic_C_"+level_class(level)+"_AU_NAT_C.nc", "r")
;res@txString = "SOIL INPUT"
;plot = gsn_csm_contour(wks, frho->Bulk_density*1000.,res)

var_name = (/ "rhosoil_vec", "sand_vec", "clay_vec", "silt_vec", "org_vec", "bch_vec",\
              "sucs_vec", "ssat_vec", "sfc_vec", "swilt_vec", "css_vec", "cnsd_vec", \
              "hyds_vec", "watr", "patchfrac", "SnowDepth" /)
;print(finout->swilt_vec)
do var_num = 0,dimsizes(var_name)-1
  printVarSummary(finout->$var_name(var_num)$)
  print(min(finout->$var_name(var_num)$))
  print(max(finout->$var_name(var_num)$))
  res@txString = var_name(var_num)
  plot = gsn_csm_contour(wks,finout->$var_name(var_num)$(0,:,:),res)
end do

; ----------------- 2D --------------------

var_name_2D = (/ "rhosoil", "sand", "clay", "silt", "organic", "bch",\
              "sucs", "ssat", "sfc", "swilt", "css", "cnsd", "hyds", "isoil",\
              "iveg", "landsea", "soil_color", "Albedo", "albedo2",   \
              "Sy", "dtb", "drainage_density", "slope", "slope_std",  \
              "elevation", "elevation_std", "permeability"             /)

do var_num = 0,dimsizes(var_name_2D)-1
  print(var_name_2D(var_num))
  res@txString = var_name_2D(var_num)
  plot = gsn_csm_contour(wks,finout->$var_name_2D(var_num)$,res)
end do


nml_4D = (/"SoilMoist","SoilTemp"/)
do var_num = 0,dimsizes(nml_4D)-1
  res@txString = nml_4D(var_num)
  plot = gsn_csm_contour(wks,finout->$nml_4D(var_num)$(0,0,:,:),res)
end do

end
