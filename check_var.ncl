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
    pic = "check_value_CSIRO"
    level_class = (/"000-005","005-015","015-030","030-060","060-100","100-200"/)
    file_end_name = "AU_NAT_C.nc"
else if soil_data_type .eq. 1 then
    fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/gridinfo_AWAP_OpenLandMap.nc"
    finout  = addfile (fname_inout, "r")     ; open output file
    pic = "check_value_OpenLandMap"
    level_class = (/"0cm","10cm","30cm","60cm","100cm","200cm"/)
    file_end_name = "OpenLandMap.nc"
end if
end if


fname_old = "/srv/ccrc/data25/z5218916/script/surface_data_for_AWAP/nc_files/MD_elev_orig_std_avg-sand_AWAP_AU_mask.nc"
                 ;lat from + to - lon from -180 to 180
fold      = addfile (fname_old,"r")
;pic = "check_value_old_AWAP_gridinfo"

;fname_LAI  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/lai_climatology_AWAP_grid.nc" ; Gimms
fname_LAI  = "/srv/ccrc/data04/z3509830/Fluxnet_data/All_flux_sites_processed/Copernicus_LAI_time_series/Aus/monthly_climatology.nc" ; Anna's Copernicus
fLAI       = addfile(fname_LAI, "r")

; _________________________ Check Value ____________________________
pic = "check_value_OpenLandMap_SoilTemp"
wks = gsn_open_wks("pdf",pic)
gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")
res            = True
res@cnFillMode = "RasterFill"            ; Raster Mode
res@cnFillOn   = True
res@cnLinesOn  = False
res@cnExplicitLabelBarLabelsOn = True   ;?
res@cnLevelSelectionMode = "ExplicitLevels"

; ==================== LAI Compare ====================
;print("a")
;res@tiMainString = "LAI"
;plot = gsn_csm_contour(wks, fLAI->LAI(0,:,:),res)
;plot = gsn_csm_contour(wks,finout->LAI(0,:,:),res)
;print("b")

; ==================== Metadata ====================
;var_name_meta = (/"Sand","Clay","Silt","Organic_C"/)

;;file_name  = addfile("/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/Bulk_density_"+level_class(level)+"_AU_NAT_C.nc", "r")
;do var_num = 0,dimsizes(var_name_meta)-1
;  do level = 0,5
;    file_name = addfile("/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/" \
;                + var_name_meta(var_num) + "_" + level_class(level) + "_" + file_end_name, "r")
;    res@tiMainString = "Metadata :"+ var_name_meta(var_num)+" "+level
;    res@cnLevels = fspan(0.,1.,11)
;    plot = gsn_csm_contour(wks, file_name->$var_name_meta(var_num)$/100.,res)
;  end do
;end do

; ; ==================== Grid File ====================
; var_name = (/ "sand_vec", "clay_vec", "silt_vec", "org_vec" /)
;             ;(/ "rhosoil_vec", "sand_vec", "clay_vec", "silt_vec", "org_vec", "bch_vec",\
;             ;  "sucs_vec", "ssat_vec", "sfc_vec", "swilt_vec", "css_vec", "cnsd_vec", \
;             ;  "hyds_vec", "watr", "patchfrac", "SnowDepth" /)
;
; do var_num = 0,dimsizes(var_name)-1
;   printVarSummary(finout->$var_name(var_num)$)
;   print(min(finout->$var_name(var_num)$))
;   print(max(finout->$var_name(var_num)$))
;   res@cnLevels = fspan(0.,1.,11)
;   do level = 0,5
;     res@tiMainString = var_name(var_num) +" "+ level
;     plot = gsn_csm_contour(wks,finout->$var_name(var_num)$(level,:,:),res)
;     ;plot = gsn_csm_contour(wks,fold->$var_name(var_num)$(level,:,:),res)
;   end do
; end do
; delete(res@cnLevels)
;
; res@cnLevels = (/-0.01,-0.001,0.,0.001,0.01/)
; do level = 0,5
;   res@tiMainString = "sand+clay+silt - 1. in level "+level
;   plot = gsn_csm_contour(wks, (finout->sand_vec(level,:,:) + finout->clay_vec(level,:,:)\
;          + finout->silt_vec(level,:,:)) -1.,res)
;   ;plot = gsn_csm_contour(wks, (fold->sand_vec(level,:,:) + fold->clay_vec(level,:,:)\
;   ;       + fold->silt_vec(level,:,:)) -1.,res)
; end do
; delete(res@cnLevels)
; ; ----------------- 2D --------------------
;
; var_name_2D = (/ "sand", "clay", "silt", "organic"/)
;             ;(/ "rhosoil", "sand", "clay", "silt", "organic", "bch",\
;             ;  "sucs", "ssat", "sfc", "swilt", "css", "cnsd", "hyds", "isoil",\
;             ;  "iveg", "landsea", "soil_color", "Albedo", "albedo2",   \
;             ;  "Sy", "dtb", "drainage_density", "slope", "slope_std",  \
;             ;  "elevation", "elevation_std", "permeability"             /)
;
; do var_num = 0,dimsizes(var_name_2D)-1
;   print(var_name_2D(var_num))
;   res@tiMainString = var_name_2D(var_num)
;   res@cnLevels = fspan(0.,1.,11)
;   plot = gsn_csm_contour(wks,finout->$var_name_2D(var_num)$,res)
;   ;plot = gsn_csm_contour(wks,fold->$var_name_2D(var_num)$,res)
; end do
;
; delete(res@cnLevels)
;
; res@cnLevels = (/-0.01,-0.001,0.,0.001,0.01/)
; res@tiMainString = "sand+clay+silt - 1."
; plot = gsn_csm_contour(wks, (finout->sand + finout->clay + finout->silt) -1.,res)
; ;plot = gsn_csm_contour(wks, (fold->sand + fold->clay + fold->silt) -1.,res)
; ;print((finout->sand + finout->clay + finout->silt) -1.)
; delete(res@cnLevels)

;nml_4D = (/"SoilMoist","SoilTemp"/)
;
;do var_num = 0,dimsizes(nml_4D)-1
;  res@tiMainString = nml_4D(var_num)
;  plot = gsn_csm_contour(wks,finout->$nml_4D(var_num)$(0,0,:,:),res)
;end do
;(finout->landsea .eq. 0.) .and.                    \

do time = 0,11
  do level = 0,5
    temp = where( ((finout->SoilTemp(time,level,:,:) .lt. 180.)       \
                  .or. (finout->SoilTemp(time,level,:,:) .gt. 350.)),\
                   -1000, 0.)
    res@tiMainString = "SoilTemp time "+time+" level "+level
    plot = gsn_csm_contour(wks,temp,res)
  end do
end do
end
