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
    fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/gridinfo_AWAP_CSIRO_AU_NAT.nc"
    finout  = addfile (fname_inout, "r")     ; open output file
    pic = "check_value_diff_CSIRO"
else if soil_data_type .eq. 1 then
    fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/gridinfo_AWAP_OpenLandMap.nc"
    finout  = addfile (fname_inout, "r")     ; open output file
    pic = "check_value_diff_OpenLandMap"
end if
end if

fname_cpr  = "/srv/ccrc/data25/z5218916/script/surface_data_for_AWAP/nc_files/MD_elev_orig_std_avg-sand_AWAP_AU_mask.nc"
fcpr       = addfile (fname_cpr, "r")     ; open output file

; _________________________ Check Value ____________________________
wks = gsn_open_wks("pdf",pic)
gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")
res            = True
res@cnFillMode = "RasterFill"            ; Raster Mode
res@cnFillOn   = True
res@cnLinesOn  = False

print("isoil")
print(finout->isoil@_FillValue)
print(fcpr->isoil@_FillValue)
res@tiMainString = "isoil"

tmp = where( finout->isoil*1 .eq. fcpr->isoil*1, \
             0, -5 )
tmp1 = where( ismissing(finout->isoil) .and. (.not. ismissing(fcpr->isoil)) , 15, -5)
tmp2 = where( ( .not. ismissing(finout->isoil)) .and. ismissing(fcpr->isoil) , 15, -5)

plot = gsn_csm_contour(wks, tmp, res)
plot = gsn_csm_contour(wks, tmp1, res)
plot = gsn_csm_contour(wks, tmp2, res)

delete(tmp)



; var_name = (/ "LAI", "rhosoil_vec", "sand_vec", "clay_vec", "silt_vec", "org_vec", "bch_vec",\
;               "sucs_vec", "ssat_vec", "sfc_vec", "swilt_vec", "css_vec", "cnsd_vec", \
;               "hyds_vec", "watr", "patchfrac", "SnowDepth" /)
;
; do var_num = 0,dimsizes(var_name)-1
;     printVarSummary(finout->$var_name(var_num)$)
;     print(finout->$var_name(var_num)$@_FillValue)
;     print(fcpr->$var_name(var_num)$@_FillValue)
;     res@tiMainString = var_name(var_num)
;
;     tmp = where( finout->$var_name(var_num)$*1. .eq. fcpr->$var_name(var_num)$*1., \
;                  0., -1. )
;     tmp = where( ismissing(finout->$var_name(var_num)$) .and. tmp .ne. 0., 1., tmp)
;     tmp = where( ismissing(fcpr->$var_name(var_num)$) .and. tmp .ne. 0., 2., tmp)
;
;     plot = gsn_csm_contour(wks, tmp(0,:,:), res)
;     delete(tmp)
; end do
;
;
; ; ----------------- 2D --------------------
;
; var_name_2D = (/"rhosoil", "sand", "clay", "silt", "organic", "bch",\
;               "sucs", "ssat", "sfc", "swilt", "css", "cnsd", "hyds", \
;               "iveg", "landsea", "soil_color", "Albedo", "albedo2",   \
;               "Sy", "dtb", "drainage_density", "slope", "slope_std",  \
;               "elevation", "elevation_std", "permeability","isoil"    /)
;
; do var_num = 0,dimsizes(var_name_2D)-1
;     print(var_name_2D(var_num))
;     print(finout->$var_name_2D(var_num)$@_FillValue)
;     print(fcpr->$var_name_2D(var_num)$@_FillValue)
;     res@tiMainString = var_name_2D(var_num)
;
;     tmp = where( finout->$var_name_2D(var_num)$*1. .eq. fcpr->$var_name_2D(var_num)$*1., \
;                  0., -1. )
;     tmp = where( ismissing(finout->$var_name_2D(var_num)$) .and. tmp .ne. 0., 1., tmp)
;     tmp = where( ismissing(fcpr->$var_name_2D(var_num)$) .and. tmp .ne. 0., 2., tmp)
;
;     plot = gsn_csm_contour(wks, tmp, res)
;
;     delete(tmp)
; end do
;
; nml_4D = (/"SoilMoist","SoilTemp"/)
; do var_num = 0,dimsizes(nml_4D)-1
;     print(nml_4D(var_num))
;     print(finout->$nml_4D(var_num)$@_FillValue)
;     print(fcpr->$nml_4D(var_num)$@_FillValue)
;     res@tiMainString = nml_4D(var_num)
;
;     tmp = where( finout->$nml_4D(var_num)$*1. .eq. fcpr->$nml_4D(var_num)$*1., \
;                  0., -1. )
;     tmp = where( ismissing(finout->$nml_4D(var_num)$) .and. tmp .ne. 0., 1., tmp)
;     tmp = where( ismissing(fcpr->$nml_4D(var_num)$) .and. tmp .ne. 0., 2., tmp)
;
;     plot = gsn_csm_contour(wks, tmp(0,0,:,:), res)
;
;     delete(tmp)
;
; end do

end
