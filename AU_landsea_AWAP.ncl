;****************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________

begin

casename = (/\
            "GADY-CABLE_orig",\
            "GADY-CABLE_orig_std",\
            "MD_elev_orig",\
            "MD_elev_orig_std",\
            "MD_elev_orig_std_avg-sand"\
           /)


; __________________________ options ____________________________
ip_opt = "orig" ;"bilinear" ;"orig"

; __________________________ PLOT SETTING ____________________________
pic = "check_AU_landsea_AWAP"
wks = gsn_open_wks("pdf",pic)
gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")

res                    = True
res@cnFillMode         = "RasterFill"            ; Raster Mode
res@cnFillOn           = True
res@tmBorderThicknessF = 3.0

res@gsnDraw            = True  ; Don't draw plots
res@gsnFrame           = True
res@lbLabelBarOn       = True
res@cnLinesOn          = False   
;res@gsnAddCyclic       = False

; ___________________________ make landsea ___________________________ 
file_name1 = "/short/w35/mm3972/data/AWAP_to_netcdf/Wind/AWAP.Wind.3hr.2000.nc"
file_name2 = "/short/w35/mm3972/cable/src/CABLE-AUX/offline/gridinfo_mmy_MD_elev_orig_std_avg-sand_landmask.nc"

f1 = addfile (file_name1,"r")
f2 = addfile (file_name2,"r")

Wind    = f1->Wind(12,:,:)
lat     = f1->lat
lon     = f1->lon

Wind!0   = "lat"
Wind!1   = "lon"
Wind&lat = lat*1.0
Wind&lon = lon*1.0

lat!0    = "lat"
lat&lat  = lat*1.0
lon!0    = "lon"
lon&lon  = lon*1.0

plot = gsn_csm_contour(wks,Wind,res)

Landsea = f2->landsea({-44:-10},{112:154})
Lat     = f2->latitude({-44:-10})
Lon     = f2->longitude({112:154})
printVarSummary(Lat)
printVarSummary(Lon)

plot = gsn_csm_contour(wks,Landsea,res)

if ip_opt .eq. "bilinear" then
   landsea = linint2(Lon,Lat,Landsea,True,lon,lat,0)
else if ip_opt .eq. "orig" then
   landsea   = new((/681,841/),  float)
   landsea!0   = "lat"
   landsea!1   = "lon"
   landsea&lat = lat*1.0
   landsea&lon = lon*1.0
   do x = -43.75,-10.25,0.5
      do y = 112.25,153.75,0.5
           landsea({x-0.25:x+0.25},{y-0.25:y+0.25}) = Landsea({x},{y})
      end do
   end do
end if
end if


delete(Landsea)
delete(Lat)
delete(Lon)
;delete(lat)
;delete(lon)

plot = gsn_csm_contour(wks,landsea,res)

landsea = where( .not. ismissing(Wind) .and. landsea .eq. 0, 0 ,1)
;delete(Wind)
plot = gsn_csm_contour(wks,landsea,res)

; ______________________________ Forming nc data ____________________________

filo = "/short/w35/mm3972/scripts/surface_data_for_AWAP/"+casename(4)+"_AWAP_AU_landmask.nc"

system("/bin/rm -f " + filo)    ; remove if exists
fout  = addfile (filo, "c")     ; open output file

; explicitly declare file definition mode. Improve efficiency.
setfileoption(fout,"DefineMode",True)

; create global attributes of the file
fAtt               = True            ; assign file attributes
fAtt@title         = "Australia landmask for gridinfo_mmy to run with AWAP data"
fAtt@source_file   = file_name1+" & "+file_name2
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( fout, fAtt )            ; copy file attributes

; predefine the coordinate variables and their dimensionality
; Note: to get an UNLIMITED record dimension, we set the dimensionality
; to -1 (or the actual size) and set the dimension name to True.

nlat   = 681 ;
nlon   = 841

dimNames = (/ "lat", "lon" /)
dimSizes = (/ nlat , nlon  /)
dimUnlim = (/ False, False /)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

; predefine the the dimensionality of the variables to be written out
print("Predefine")

filevardef(fout, "landsea",typeof(Wind),getvardims(Wind))
filevardef(fout, "lat",typeof(lat),getvardims(lat))
filevardef(fout, "lon",typeof(lon),getvardims(lon))
printVarSummary(fout->landsea)
;fout->landsea!0 = "lat"
;fout->landsea!1 = "lon"
;lat = dble2flt(f1->lat);(::-1)
;lon = dble2flt(f1->lon)
;var1&lat = lat
;var1&lon = lon


print("Copy attributes")
filevarattdef(fout,"landsea",f2->landsea)
filevarattdef(fout,"lat",lat)
filevarattdef(fout,"lon",lon)
setfileoption(fout,"DefineMode",False)
print("Exit DefineMode")

fout->landsea = landsea
fout->lat  = lat
fout->lon  = lon

res@gsnAddCyclic       = False
plot = gsn_csm_contour_map(wks,fout->landsea,res)

end

