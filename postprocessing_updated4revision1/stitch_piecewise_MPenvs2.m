

clear 


direct = '/Users/marq789/Documents/PROJECTS/WACCEM/MPera5envs/piecewise/' ;

% ncdisp('/Users/marq789/Documents/PROJECTS/WACCEM/MPera5envs/piecewise/mcs_era5_afwa_20140501.0000_20140831.2300_t1400.nc')

% ncdisp('/Users/marq789/Documents/PROJECTS/WACCEM/MPera5envs/piecewise/mcs_era5_afwa_20050501.0000_20050831.2300_t0000.nc')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%      2014 AFWA:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tracklist = ls( horzcat(direct,'mcs_era5_afwa_201405*') );
filelist = split(tracklist);  filelist(end) = [];
[sa sb] = size(filelist) ; clear sb;

% ncdisp( char(filelist(1)) )

tracktimes    = 800;
chunksize     = 50;

% lasttrack2005 = 1370 + 1 ;
% lasttrack2012 = 1453 + 1 ;
% lasttrack2014 = 1495 + 1 ;
% lasttrack2016 = 1428 + 1 ;

lasttrack2005 = 1370  ;
lasttrack2012 = 1453  ;
lasttrack2014 = 1495  ;
lasttrack2016 = 1428  ;

%seed arrays:
dummy = zeros(tracktimes,lasttrack2014);    dummy(:) = NaN;
[meanMUCAPE, maxMUCAPE, meanMUCIN, minMUCIN, meanMULFC, meanMUEL, meanPW, maxPW, minPW ] = deal(dummy);

for tf = 1 : length(filelist)
    clear var tracks
    tracks = ncread( char(filelist(tf))  ,'tracks') ;
    times = ncread( char(filelist(tf))  ,'times') ;
    tracks = tracks + 1 ;  %python -> matlab indices
    times = times + 1;

    var        = ncread( char(filelist(tf))  ,'meanMUCAPE') ;
    meanMUCAPE(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxMUCAPE') ;
    maxMUCAPE(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanMUCIN') ;
    meanMUCIN(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minMUCIN') ;
    minMUCIN(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanMULFC') ;
    meanMULFC(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanMUEL') ;
    meanMUEL(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanPW') ;
    meanPW(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxPW') ;
    maxPW(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minPW') ;
    minPW(times(1):times(end),tracks(1):tracks(end)) = var ;

end

ncfile = [direct,'AFWA_2014_piecewise.nc'];

[xl yl] = size(meanMUCAPE);
nccreate(ncfile,'meanMUCAPE',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanMUCAPE',meanMUCAPE) ;
ncwriteatt(ncfile,'meanMUCAPE','units','j/kg');
ncwriteatt(ncfile,'meanMUCAPE','description',' ');

[xl yl] = size(maxMUCAPE);
nccreate(ncfile,'maxMUCAPE',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxMUCAPE',maxMUCAPE) ;
ncwriteatt(ncfile,'maxMUCAPE','units','j/kg');
ncwriteatt(ncfile,'maxMUCAPE','description',' ');

[xl yl] = size(meanMUCIN);
nccreate(ncfile,'meanMUCIN',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanMUCIN',meanMUCIN) ;
ncwriteatt(ncfile,'meanMUCIN','units','j/kg');
ncwriteatt(ncfile,'meanMUCIN','description',' ');

[xl yl] = size(minMUCIN);
nccreate(ncfile,'minMUCIN',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minMUCIN',minMUCIN) ;
ncwriteatt(ncfile,'minMUCIN','units','j/kg');
ncwriteatt(ncfile,'minMUCIN','description',' ');

[xl yl] = size(meanMULFC);
nccreate(ncfile,'meanMULFC',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanMULFC',meanMULFC) ;
ncwriteatt(ncfile,'meanMULFC','units','m');
ncwriteatt(ncfile,'meanMULFC','description',' ');

[xl yl] = size(meanMUEL);
nccreate(ncfile,'meanMUEL',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanMUEL',meanMUEL) ;
ncwriteatt(ncfile,'meanMUEL','units','m');
ncwriteatt(ncfile,'meanMUEL','description',' ');

[xl yl] = size(meanPW);
nccreate(ncfile,'meanPW',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanPW',meanPW) ;
ncwriteatt(ncfile,'meanPW','units',' ');
ncwriteatt(ncfile,'meanPW','description',' ');

[xl yl] = size(maxPW);
nccreate(ncfile,'maxPW',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxPW',maxPW) ;
ncwriteatt(ncfile,'maxPW','units',' ');
ncwriteatt(ncfile,'maxPW','description',' ');

[xl yl] = size(minPW);
nccreate(ncfile,'minPW',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minPW',minPW) ;
ncwriteatt(ncfile,'minPW','units',' ');
ncwriteatt(ncfile,'minPW','description',' ');







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%      2014 kinem:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tracklist = ls( horzcat(direct,'mcs_era5_kinem_201405*') );
filelist = split(tracklist);  filelist(end) = [];
[sa sb] = size(filelist) ; clear sb;

% ncdisp( char(filelist(1)) )

% tracktimes    = 400;
% chunksize     = 50;

% lasttrack2005 = 1370 + 1 ;
% lasttrack2012 = 1453 + 1 ;
% lasttrack2014 = 1495 + 1 ;
% lasttrack2016 = 1428 + 1 ;

%seed arrays:
dummy = zeros(tracktimes,lasttrack2014);    dummy(:) = NaN;
[meanshearmag2to9,maxshearmag2to9,meanshearmag0to2,maxshearmag0to2,meanshearmag0to6,maxshearmag0to6,...
    meanOMEGA600,minOMEGA600,minOMEGAsub600,meanVIWVD,maxVIWVD,minVIWVD,meanDIV750,minDIV750,minDIVsub600,...
    meanWNDSPD600,meanWNDDIR600] = deal(dummy);

for tf = 1 : length(filelist)
    clear var tracks
    tracks = ncread( char(filelist(tf))  ,'tracks') ;
    times = ncread( char(filelist(tf))  ,'times') ;
    tracks = tracks + 1 ;  %python -> matlab indices
    times = times + 1;

    var        = ncread( char(filelist(tf))  ,'meanshearmag2to9') ;
    meanshearmag2to9(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxshearmag2to9') ;
    maxshearmag2to9(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanshearmag0to2') ;
    meanshearmag0to2(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxshearmag0to2') ;
    maxshearmag0to2(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanshearmag0to6') ;
    meanshearmag0to6(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxshearmag0to6') ;
    maxshearmag0to6(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanOMEGA600') ;
    meanOMEGA600(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minOMEGA600') ;
    minOMEGA600(times(1):times(end),tracks(1):tracks(end)) = var ; 

    var        = ncread( char(filelist(tf))  ,'minOMEGAsub600') ;
    minOMEGAsub600(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanVIWVD') ;
    meanVIWVD(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minVIWVD') ;
    minVIWVD(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxVIWVD') ;
    maxVIWVD(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanDIV750') ;
    meanDIV750(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minDIV750') ;
    minDIV750(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minDIVsub600') ;
    minDIVsub600(times(1):times(end),tracks(1):tracks(end)) = var ;    

    var        = ncread( char(filelist(tf))  ,'meanWNDSPD600') ;
    meanWNDSPD600(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanWNDDIR600') ;
    meanWNDDIR600(times(1):times(end),tracks(1):tracks(end)) = var ;    
end

ncfile = [direct,'KINEM_2014_piecewise.nc'];

[xl yl] = size(meanshearmag2to9);
nccreate(ncfile,'meanshearmag2to9',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanshearmag2to9',meanshearmag2to9) ;
ncwriteatt(ncfile,'meanshearmag2to9','units',' ');
ncwriteatt(ncfile,'meanshearmag2to9','description',' ');

[xl yl] = size(maxshearmag2to9);
nccreate(ncfile,'maxshearmag2to9',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxshearmag2to9',maxshearmag2to9) ;
ncwriteatt(ncfile,'maxshearmag2to9','units',' ');
ncwriteatt(ncfile,'maxshearmag2to9','description',' ');

[xl yl] = size(meanshearmag0to2);
nccreate(ncfile,'meanshearmag0to2',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanshearmag0to2',meanshearmag0to2) ;
ncwriteatt(ncfile,'meanshearmag0to2','units',' ');
ncwriteatt(ncfile,'meanshearmag0to2','description',' ');

[xl yl] = size(maxshearmag0to2);
nccreate(ncfile,'maxshearmag0to2',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxshearmag0to2',maxshearmag0to2) ;
ncwriteatt(ncfile,'maxshearmag0to2','units',' ');
ncwriteatt(ncfile,'maxshearmag0to2','description',' ');

[xl yl] = size(meanshearmag0to6);
nccreate(ncfile,'meanshearmag0to6',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanshearmag0to6',meanshearmag0to6) ;
ncwriteatt(ncfile,'meanshearmag0to6','units',' ');
ncwriteatt(ncfile,'meanshearmag0to6','description',' ');

[xl yl] = size(maxshearmag0to6);
nccreate(ncfile,'maxshearmag0to6',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxshearmag0to6',maxshearmag0to6) ;
ncwriteatt(ncfile,'maxshearmag0to6','units',' ');
ncwriteatt(ncfile,'maxshearmag0to6','description',' ');


[xl yl] = size(meanOMEGA600);
nccreate(ncfile,'meanOMEGA600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanOMEGA600',meanOMEGA600) ;
ncwriteatt(ncfile,'meanOMEGA600','units', ' ');
ncwriteatt(ncfile,'meanOMEGA600','description',' ');

[xl yl] = size(minOMEGA600) ;
nccreate(ncfile,'minOMEGA600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minOMEGA600',minOMEGA600) ;
ncwriteatt(ncfile,'minOMEGA600','units', ' ');
ncwriteatt(ncfile,'minOMEGA600','description',' ');


[xl yl] = size(minOMEGAsub600);
nccreate(ncfile,'minOMEGAsub600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minOMEGAsub600',minOMEGAsub600) ;
ncwriteatt(ncfile,'minOMEGAsub600','units',' ');
ncwriteatt(ncfile,'minOMEGAsub600','description',' ');


[xl yl] = size(meanVIWVD);
nccreate(ncfile,'meanVIWVD',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanVIWVD',meanVIWVD) ;
ncwriteatt(ncfile,'meanVIWVD','units',' ');
ncwriteatt(ncfile,'meanVIWVD','description',' ');

[xl yl] = size(maxVIWVD);
nccreate(ncfile,'maxVIWVD',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxVIWVD',maxVIWVD) ;
ncwriteatt(ncfile,'maxVIWVD','units',' ');
ncwriteatt(ncfile,'maxVIWVD','description',' ');

[xl yl] = size(minVIWVD);
nccreate(ncfile,'minVIWVD',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minVIWVD',minVIWVD) ;
ncwriteatt(ncfile,'minVIWVD','units',' ');
ncwriteatt(ncfile,'minVIWVD','description',' ');



[xl yl] = size(meanDIV750);
nccreate(ncfile,'meanDIV750',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanDIV750',meanDIV750) ;
ncwriteatt(ncfile,'meanDIV750','units',' ');
ncwriteatt(ncfile,'meanDIV750','description',' ');

[xl yl] = size(minDIV750);
nccreate(ncfile,'minDIV750',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minDIV750',minDIV750) ;
ncwriteatt(ncfile,'minDIV750','units',' ');
ncwriteatt(ncfile,'minDIV750','description',' ');

[xl yl] = size(minDIVsub600);
nccreate(ncfile,'minDIVsub600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minDIVsub600',minDIVsub600) ;
ncwriteatt(ncfile,'minDIVsub600','units',' ');
ncwriteatt(ncfile,'minDIVsub600','description',' ');


[xl yl] = size(meanWNDSPD600);
nccreate(ncfile,'meanWNDSPD600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanWNDSPD600',meanWNDSPD600) ;
ncwriteatt(ncfile,'meanWNDSPD600','units',' ');
ncwriteatt(ncfile,'meanWNDSPD600','description',' ');

[xl yl] = size(meanWNDDIR600);
nccreate(ncfile,'meanWNDDIR600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanWNDDIR600',meanWNDDIR600) ;
ncwriteatt(ncfile,'meanWNDDIR600','units',' ');
ncwriteatt(ncfile,'meanWNDDIR600','description',' ');







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%      2005 kinem:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tracklist = ls( horzcat(direct,'mcs_era5_kinem_200505*') );

ncfile = [direct,'KINEM_2005_piecewise.nc'];

filelist = split(tracklist);  filelist(end) = [];
[sa sb] = size(filelist) ; clear sb;

% ncdisp( char(filelist(1)) )

% tracktimes    = 400;
% chunksize     = 50;

% lasttrack2005 = 1370 + 1 ;
% lasttrack2012 = 1453 + 1 ;
% lasttrack2014 = 1495 + 1 ;
% lasttrack2016 = 1428 + 1 ;

%seed arrays:
dummy = zeros(tracktimes,lasttrack2005);    dummy(:) = NaN;
[meanshearmag2to9,maxshearmag2to9,meanshearmag0to2,maxshearmag0to2,meanshearmag0to6,maxshearmag0to6,...
    meanOMEGA600,minOMEGA600,minOMEGAsub600,meanVIWVD,maxVIWVD,minVIWVD,meanDIV750,minDIV750,minDIVsub600,...
    meanWNDSPD600,meanWNDDIR600] = deal(dummy);

for tf = 1 : length(filelist)
    clear var tracks
    tracks = ncread( char(filelist(tf))  ,'tracks') ;
    times = ncread( char(filelist(tf))  ,'times') ;
    tracks = tracks + 1 ;  %python -> matlab indices
    times = times + 1;

    var        = ncread( char(filelist(tf))  ,'meanshearmag2to9') ;
    meanshearmag2to9(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxshearmag2to9') ;
    maxshearmag2to9(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanshearmag0to2') ;
    meanshearmag0to2(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxshearmag0to2') ;
    maxshearmag0to2(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanshearmag0to6') ;
    meanshearmag0to6(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxshearmag0to6') ;
    maxshearmag0to6(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanOMEGA600') ;
    meanOMEGA600(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minOMEGA600') ;
    minOMEGA600(times(1):times(end),tracks(1):tracks(end)) = var ; 

    var        = ncread( char(filelist(tf))  ,'minOMEGAsub600') ;
    minOMEGAsub600(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanVIWVD') ;
    meanVIWVD(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minVIWVD') ;
    minVIWVD(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxVIWVD') ;
    maxVIWVD(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanDIV750') ;
    meanDIV750(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minDIV750') ;
    minDIV750(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minDIVsub600') ;
    minDIVsub600(times(1):times(end),tracks(1):tracks(end)) = var ;    

    var        = ncread( char(filelist(tf))  ,'meanWNDSPD600') ;
    meanWNDSPD600(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanWNDDIR600') ;
    meanWNDDIR600(times(1):times(end),tracks(1):tracks(end)) = var ;  

end


[xl yl] = size(meanshearmag2to9);
nccreate(ncfile,'meanshearmag2to9',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanshearmag2to9',meanshearmag2to9) ;
ncwriteatt(ncfile,'meanshearmag2to9','units',' ');
ncwriteatt(ncfile,'meanshearmag2to9','description',' ');

[xl yl] = size(maxshearmag2to9);
nccreate(ncfile,'maxshearmag2to9',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxshearmag2to9',maxshearmag2to9) ;
ncwriteatt(ncfile,'maxshearmag2to9','units',' ');
ncwriteatt(ncfile,'maxshearmag2to9','description',' ');

[xl yl] = size(meanshearmag0to2);
nccreate(ncfile,'meanshearmag0to2',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanshearmag0to2',meanshearmag0to2) ;
ncwriteatt(ncfile,'meanshearmag0to2','units',' ');
ncwriteatt(ncfile,'meanshearmag0to2','description',' ');

[xl yl] = size(maxshearmag0to2);
nccreate(ncfile,'maxshearmag0to2',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxshearmag0to2',maxshearmag0to2) ;
ncwriteatt(ncfile,'maxshearmag0to2','units',' ');
ncwriteatt(ncfile,'maxshearmag0to2','description',' ');

[xl yl] = size(meanshearmag0to6);
nccreate(ncfile,'meanshearmag0to6',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanshearmag0to6',meanshearmag0to6) ;
ncwriteatt(ncfile,'meanshearmag0to6','units',' ');
ncwriteatt(ncfile,'meanshearmag0to6','description',' ');

[xl yl] = size(maxshearmag0to6);
nccreate(ncfile,'maxshearmag0to6',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxshearmag0to6',maxshearmag0to6) ;
ncwriteatt(ncfile,'maxshearmag0to6','units',' ');
ncwriteatt(ncfile,'maxshearmag0to6','description',' ');


[xl yl] = size(meanOMEGA600);
nccreate(ncfile,'meanOMEGA600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanOMEGA600',meanOMEGA600) ;
ncwriteatt(ncfile,'meanOMEGA600','units', ' ');
ncwriteatt(ncfile,'meanOMEGA600','description',' ');

[xl yl] = size(minOMEGA600);
nccreate(ncfile,'minOMEGA600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minOMEGA600',minOMEGA600) ;
ncwriteatt(ncfile,'minOMEGA600','units', ' ');
ncwriteatt(ncfile,'minOMEGA600','description',' ');


[xl yl] = size(minOMEGAsub600);
nccreate(ncfile,'minOMEGAsub600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minOMEGAsub600',minOMEGAsub600) ;
ncwriteatt(ncfile,'minOMEGAsub600','units',' ');
ncwriteatt(ncfile,'minOMEGAsub600','description',' ');


[xl yl] = size(meanVIWVD);
nccreate(ncfile,'meanVIWVD',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanVIWVD',meanVIWVD) ;
ncwriteatt(ncfile,'meanVIWVD','units',' ');
ncwriteatt(ncfile,'meanVIWVD','description',' ');

[xl yl] = size(maxVIWVD);
nccreate(ncfile,'maxVIWVD',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxVIWVD',maxVIWVD) ;
ncwriteatt(ncfile,'maxVIWVD','units',' ');
ncwriteatt(ncfile,'maxVIWVD','description',' ');

[xl yl] = size(minVIWVD);
nccreate(ncfile,'minVIWVD',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minVIWVD',minVIWVD) ;
ncwriteatt(ncfile,'minVIWVD','units',' ');
ncwriteatt(ncfile,'minVIWVD','description',' ');



[xl yl] = size(meanDIV750);
nccreate(ncfile,'meanDIV750',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanDIV750',meanDIV750) ;
ncwriteatt(ncfile,'meanDIV750','units',' ');
ncwriteatt(ncfile,'meanDIV750','description',' ');

[xl yl] = size(minDIV750);
nccreate(ncfile,'minDIV750',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minDIV750',minDIV750) ;
ncwriteatt(ncfile,'minDIV750','units',' ');
ncwriteatt(ncfile,'minDIV750','description',' ');

[xl yl] = size(minDIVsub600);
nccreate(ncfile,'minDIVsub600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minDIVsub600',minDIVsub600) ;
ncwriteatt(ncfile,'minDIVsub600','units',' ');
ncwriteatt(ncfile,'minDIVsub600','description',' ');


[xl yl] = size(meanWNDSPD600);
nccreate(ncfile,'meanWNDSPD600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanWNDSPD600',meanWNDSPD600) ;
ncwriteatt(ncfile,'meanWNDSPD600','units',' ');
ncwriteatt(ncfile,'meanWNDSPD600','description',' ');

[xl yl] = size(meanWNDDIR600);
nccreate(ncfile,'meanWNDDIR600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanWNDDIR600',meanWNDDIR600) ;
ncwriteatt(ncfile,'meanWNDDIR600','units',' ');
ncwriteatt(ncfile,'meanWNDDIR600','description',' ');








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%      2012 kinem:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



tracklist = ls( horzcat(direct,'mcs_era5_kinem_201205*') );

ncfile = [direct,'KINEM_2012_piecewise.nc'];

filelist = split(tracklist);  filelist(end) = [];
[sa sb] = size(filelist) ; clear sb;

% ncdisp( char(filelist(1)) )

% tracktimes    = 400;
% chunksize     = 50;

% lasttrack2005 = 1370 + 1 ;
% lasttrack2012 = 1453 + 1 ;
% lasttrack2014 = 1495 + 1 ;
% lasttrack2016 = 1428 + 1 ;

%seed arrays:
dummy = zeros(tracktimes,lasttrack2012);    dummy(:) = NaN;
[meanshearmag2to9,maxshearmag2to9,meanshearmag0to2,maxshearmag0to2,meanshearmag0to6,maxshearmag0to6,...
    meanOMEGA600,minOMEGA600,minOMEGAsub600,meanVIWVD,maxVIWVD,minVIWVD,meanDIV750,minDIV750,minDIVsub600,...
    meanWNDSPD600,meanWNDDIR600] = deal(dummy);

for tf = 1 : length(filelist)
    clear var tracks
    tracks = ncread( char(filelist(tf))  ,'tracks') ;
    times = ncread( char(filelist(tf))  ,'times') ;
    tracks = tracks + 1 ;  %python -> matlab indices
    times = times + 1;

    var        = ncread( char(filelist(tf))  ,'meanshearmag2to9') ;
    meanshearmag2to9(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxshearmag2to9') ;
    maxshearmag2to9(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanshearmag0to2') ;
    meanshearmag0to2(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxshearmag0to2') ;
    maxshearmag0to2(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanshearmag0to6') ;
    meanshearmag0to6(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxshearmag0to6') ;
    maxshearmag0to6(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanOMEGA600') ;
    meanOMEGA600(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minOMEGA600') ;
    minOMEGA600(times(1):times(end),tracks(1):tracks(end)) = var ; 

    var        = ncread( char(filelist(tf))  ,'minOMEGAsub600') ;
    minOMEGAsub600(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanVIWVD') ;
    meanVIWVD(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minVIWVD') ;
    minVIWVD(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxVIWVD') ;
    maxVIWVD(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanDIV750') ;
    meanDIV750(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minDIV750') ;
    minDIV750(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minDIVsub600') ;
    minDIVsub600(times(1):times(end),tracks(1):tracks(end)) = var ;    

    var        = ncread( char(filelist(tf))  ,'meanWNDSPD600') ;
    meanWNDSPD600(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanWNDDIR600') ;
    meanWNDDIR600(times(1):times(end),tracks(1):tracks(end)) = var ; 

end


[xl yl] = size(meanshearmag2to9);
nccreate(ncfile,'meanshearmag2to9',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanshearmag2to9',meanshearmag2to9) ;
ncwriteatt(ncfile,'meanshearmag2to9','units',' ');
ncwriteatt(ncfile,'meanshearmag2to9','description',' ');

[xl yl] = size(maxshearmag2to9);
nccreate(ncfile,'maxshearmag2to9',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxshearmag2to9',maxshearmag2to9) ;
ncwriteatt(ncfile,'maxshearmag2to9','units',' ');
ncwriteatt(ncfile,'maxshearmag2to9','description',' ');

[xl yl] = size(meanshearmag0to2);
nccreate(ncfile,'meanshearmag0to2',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanshearmag0to2',meanshearmag0to2) ;
ncwriteatt(ncfile,'meanshearmag0to2','units',' ');
ncwriteatt(ncfile,'meanshearmag0to2','description',' ');

[xl yl] = size(maxshearmag0to2);
nccreate(ncfile,'maxshearmag0to2',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxshearmag0to2',maxshearmag0to2) ;
ncwriteatt(ncfile,'maxshearmag0to2','units',' ');
ncwriteatt(ncfile,'maxshearmag0to2','description',' ');

[xl yl] = size(meanshearmag0to6);
nccreate(ncfile,'meanshearmag0to6',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanshearmag0to6',meanshearmag0to6) ;
ncwriteatt(ncfile,'meanshearmag0to6','units',' ');
ncwriteatt(ncfile,'meanshearmag0to6','description',' ');

[xl yl] = size(maxshearmag0to6);
nccreate(ncfile,'maxshearmag0to6',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxshearmag0to6',maxshearmag0to6) ;
ncwriteatt(ncfile,'maxshearmag0to6','units',' ');
ncwriteatt(ncfile,'maxshearmag0to6','description',' ');


[xl yl] = size(meanOMEGA600);
nccreate(ncfile,'meanOMEGA600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanOMEGA600',meanOMEGA600) ;
ncwriteatt(ncfile,'meanOMEGA600','units', ' ');
ncwriteatt(ncfile,'meanOMEGA600','description',' ');

[xl yl] = size(minOMEGA600);
nccreate(ncfile,'minOMEGA600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minOMEGA600',minOMEGA600) ;
ncwriteatt(ncfile,'minOMEGA600','units', ' ');
ncwriteatt(ncfile,'minOMEGA600','description',' ');

[xl yl] = size(minOMEGAsub600);
nccreate(ncfile,'minOMEGAsub600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minOMEGAsub600',minOMEGAsub600) ;
ncwriteatt(ncfile,'minOMEGAsub600','units',' ');
ncwriteatt(ncfile,'minOMEGAsub600','description',' ');


[xl yl] = size(meanVIWVD);
nccreate(ncfile,'meanVIWVD',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanVIWVD',meanVIWVD) ;
ncwriteatt(ncfile,'meanVIWVD','units',' ');
ncwriteatt(ncfile,'meanVIWVD','description',' ');

[xl yl] = size(maxVIWVD);
nccreate(ncfile,'maxVIWVD',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxVIWVD',maxVIWVD) ;
ncwriteatt(ncfile,'maxVIWVD','units',' ');
ncwriteatt(ncfile,'maxVIWVD','description',' ');

[xl yl] = size(minVIWVD);
nccreate(ncfile,'minVIWVD',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minVIWVD',minVIWVD) ;
ncwriteatt(ncfile,'minVIWVD','units',' ');
ncwriteatt(ncfile,'minVIWVD','description',' ');



[xl yl] = size(meanDIV750);
nccreate(ncfile,'meanDIV750',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanDIV750',meanDIV750) ;
ncwriteatt(ncfile,'meanDIV750','units',' ');
ncwriteatt(ncfile,'meanDIV750','description',' ');

[xl yl] = size(minDIV750);
nccreate(ncfile,'minDIV750',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minDIV750',minDIV750) ;
ncwriteatt(ncfile,'minDIV750','units',' ');
ncwriteatt(ncfile,'minDIV750','description',' ');

[xl yl] = size(minDIVsub600);
nccreate(ncfile,'minDIVsub600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minDIVsub600',minDIVsub600) ;
ncwriteatt(ncfile,'minDIVsub600','units',' ');
ncwriteatt(ncfile,'minDIVsub600','description',' ');


[xl yl] = size(meanWNDSPD600);
nccreate(ncfile,'meanWNDSPD600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanWNDSPD600',meanWNDSPD600) ;
ncwriteatt(ncfile,'meanWNDSPD600','units',' ');
ncwriteatt(ncfile,'meanWNDSPD600','description',' ');

[xl yl] = size(meanWNDDIR600);
nccreate(ncfile,'meanWNDDIR600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanWNDDIR600',meanWNDDIR600) ;
ncwriteatt(ncfile,'meanWNDDIR600','units',' ');
ncwriteatt(ncfile,'meanWNDDIR600','description',' ');




%%





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%      2016 kinem:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tracklist = ls( horzcat(direct,'mcs_era5_kinem_201605*') );

ncfile = [direct,'KINEM_2016_piecewise.nc'];

filelist = split(tracklist);  filelist(end) = [];
[sa sb] = size(filelist) ; clear sb;

% ncdisp( char(filelist(1)) )

% tracktimes    = 400;
% chunksize     = 50;

% lasttrack2005 = 1370 + 1 ;
% lasttrack2012 = 1453 + 1 ;
% lasttrack2014 = 1495 + 1 ;
% lasttrack2016 = 1428 + 1 ;

%seed arrays:
dummy = zeros(tracktimes,lasttrack2016);    dummy(:) = NaN;
[meanshearmag2to9,maxshearmag2to9,meanshearmag0to2,maxshearmag0to2,meanshearmag0to6,maxshearmag0to6,...
    meanOMEGA600,minOMEGA600,minOMEGAsub600,meanVIWVD,maxVIWVD,minVIWVD,meanDIV750,minDIV750,minDIVsub600,...
    meanWNDSPD600,meanWNDDIR600] = deal(dummy);

for tf = 1 : length(filelist)
    clear var tracks
    tracks = ncread( char(filelist(tf))  ,'tracks') ;
    times = ncread( char(filelist(tf))  ,'times') ;
    tracks = tracks + 1 ;  %python -> matlab indices
    times = times + 1;

    var        = ncread( char(filelist(tf))  ,'meanshearmag2to9') ;
    meanshearmag2to9(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxshearmag2to9') ;
    maxshearmag2to9(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanshearmag0to2') ;
    meanshearmag0to2(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxshearmag0to2') ;
    maxshearmag0to2(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanshearmag0to6') ;
    meanshearmag0to6(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxshearmag0to6') ;
    maxshearmag0to6(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanOMEGA600') ;
    meanOMEGA600(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minOMEGA600') ;
    minOMEGA600(times(1):times(end),tracks(1):tracks(end)) = var ; 

    var        = ncread( char(filelist(tf))  ,'minOMEGAsub600') ;
    minOMEGAsub600(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanVIWVD') ;
    meanVIWVD(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minVIWVD') ;
    minVIWVD(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'maxVIWVD') ;
    maxVIWVD(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanDIV750') ;
    meanDIV750(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minDIV750') ;
    minDIV750(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'minDIVsub600') ;
    minDIVsub600(times(1):times(end),tracks(1):tracks(end)) = var ;    

    var        = ncread( char(filelist(tf))  ,'meanWNDSPD600') ;
    meanWNDSPD600(times(1):times(end),tracks(1):tracks(end)) = var ;

    var        = ncread( char(filelist(tf))  ,'meanWNDDIR600') ;
    meanWNDDIR600(times(1):times(end),tracks(1):tracks(end)) = var ; 

end


[xl yl] = size(meanshearmag2to9);
nccreate(ncfile,'meanshearmag2to9',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanshearmag2to9',meanshearmag2to9) ;
ncwriteatt(ncfile,'meanshearmag2to9','units',' ');
ncwriteatt(ncfile,'meanshearmag2to9','description',' ');

[xl yl] = size(maxshearmag2to9);
nccreate(ncfile,'maxshearmag2to9',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxshearmag2to9',maxshearmag2to9) ;
ncwriteatt(ncfile,'maxshearmag2to9','units',' ');
ncwriteatt(ncfile,'maxshearmag2to9','description',' ');

[xl yl] = size(meanshearmag0to2);
nccreate(ncfile,'meanshearmag0to2',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanshearmag0to2',meanshearmag0to2) ;
ncwriteatt(ncfile,'meanshearmag0to2','units',' ');
ncwriteatt(ncfile,'meanshearmag0to2','description',' ');

[xl yl] = size(maxshearmag0to2);
nccreate(ncfile,'maxshearmag0to2',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxshearmag0to2',maxshearmag0to2) ;
ncwriteatt(ncfile,'maxshearmag0to2','units',' ');
ncwriteatt(ncfile,'maxshearmag0to2','description',' ');

[xl yl] = size(meanshearmag0to6);
nccreate(ncfile,'meanshearmag0to6',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanshearmag0to6',meanshearmag0to6) ;
ncwriteatt(ncfile,'meanshearmag0to6','units',' ');
ncwriteatt(ncfile,'meanshearmag0to6','description',' ');

[xl yl] = size(maxshearmag0to6);
nccreate(ncfile,'maxshearmag0to6',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxshearmag0to6',maxshearmag0to6) ;
ncwriteatt(ncfile,'maxshearmag0to6','units',' ');
ncwriteatt(ncfile,'maxshearmag0to6','description',' ');


[xl yl] = size(meanOMEGA600);
nccreate(ncfile,'meanOMEGA600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanOMEGA600',meanOMEGA600) ;
ncwriteatt(ncfile,'meanOMEGA600','units', ' ');
ncwriteatt(ncfile,'meanOMEGA600','description',' ');

[xl yl] = size(minOMEGA600);
nccreate(ncfile,'minOMEGA600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minOMEGA600',minOMEGA600) ;
ncwriteatt(ncfile,'minOMEGA600','units', ' ');
ncwriteatt(ncfile,'minOMEGA600','description',' ');

[xl yl] = size(minOMEGAsub600);
nccreate(ncfile,'minOMEGAsub600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minOMEGAsub600',minOMEGAsub600) ;
ncwriteatt(ncfile,'minOMEGAsub600','units',' ');
ncwriteatt(ncfile,'minOMEGAsub600','description',' ');


[xl yl] = size(meanVIWVD);
nccreate(ncfile,'meanVIWVD',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanVIWVD',meanVIWVD) ;
ncwriteatt(ncfile,'meanVIWVD','units',' ');
ncwriteatt(ncfile,'meanVIWVD','description',' ');

[xl yl] = size(maxVIWVD);
nccreate(ncfile,'maxVIWVD',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'maxVIWVD',maxVIWVD) ;
ncwriteatt(ncfile,'maxVIWVD','units',' ');
ncwriteatt(ncfile,'maxVIWVD','description',' ');

[xl yl] = size(minVIWVD);
nccreate(ncfile,'minVIWVD',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minVIWVD',minVIWVD) ;
ncwriteatt(ncfile,'minVIWVD','units',' ');
ncwriteatt(ncfile,'minVIWVD','description',' ');



[xl yl] = size(meanDIV750);
nccreate(ncfile,'meanDIV750',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanDIV750',meanDIV750) ;
ncwriteatt(ncfile,'meanDIV750','units',' ');
ncwriteatt(ncfile,'meanDIV750','description',' ');

[xl yl] = size(minDIV750);
nccreate(ncfile,'minDIV750',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minDIV750',minDIV750) ;
ncwriteatt(ncfile,'minDIV750','units',' ');
ncwriteatt(ncfile,'minDIV750','description',' ');

[xl yl] = size(minDIVsub600);
nccreate(ncfile,'minDIVsub600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'minDIVsub600',minDIVsub600) ;
ncwriteatt(ncfile,'minDIVsub600','units',' ');
ncwriteatt(ncfile,'minDIVsub600','description',' ');


[xl yl] = size(meanWNDSPD600);
nccreate(ncfile,'meanWNDSPD600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanWNDSPD600',meanWNDSPD600) ;
ncwriteatt(ncfile,'meanWNDSPD600','units',' ');
ncwriteatt(ncfile,'meanWNDSPD600','description',' ');

[xl yl] = size(meanWNDDIR600);
nccreate(ncfile,'meanWNDDIR600',...
    'Dimensions', {'times',xl,'tracks',yl},...
    'FillValue','disable');
ncwrite(ncfile,'meanWNDDIR600',meanWNDDIR600) ;
ncwriteatt(ncfile,'meanWNDDIR600','units',' ');
ncwriteatt(ncfile,'meanWNDDIR600','description',' ');





%{

ncdisp(  '/Users/marq789/Documents/PROJECTS/WACCEM/MPera5envs/piecewise/AFWA_2014_piecewise.nc' )

ncdisp(  '/Users/marq789/Documents/PROJECTS/WACCEM/MPera5envs/piecewise/KINEM_2005_piecewise.nc' )

ncdisp(  '/Users/marq789/Documents/PROJECTS/WACCEM/MPera5envs/piecewise/KINEM_2012_piecewise.nc' )

ncdisp(  '/Users/marq789/Documents/PROJECTS/WACCEM/MPera5envs/piecewise/KINEM_2014_piecewise.nc' )

ncdisp(  '/Users/marq789/Documents/PROJECTS/WACCEM/MPera5envs/piecewise/KINEM_2016_piecewise.nc' )

%}


