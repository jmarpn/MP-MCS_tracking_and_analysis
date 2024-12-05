
% v4: adds in more era5 vars (cape, viwvd), goes to 2021. changed
% nomenclature of synopbjs to "MP" prefix/suffix
% v5: adds in Largest-scale synotpic objects ("LS" prefix/suffix) = (wl > 2500 km)- tracking,
%       spearating MCSs occuring with only MPs and only LSs (and neither). Also has option to recover watershed-parced LS tracks via an iterative 
%
%       ***** IMPORTANT NOTE *****  code assumes that MP and LS tracking is done on the
%       exact same ERA5 domain and time spans
%v5b:   adds subdomain mask to kill MCSs that initiate outside of a wanted lat/lon box

%v6: adds in MPstat environemtnal vars calcuated from Zhe's python codes
%(afwa vars, shear, dynamic, PW, wind, etc.)

%v7: performs for varied overlap fraction (prescribed by you) between MCS-LS, MCS-MP in order to
%address sensitivity to collocation methods

%v7b: fixes gross error in which years 2005,2014,2012,2016 were missing
%some of their thermo and wind data, which had to be piecwwise sticthed together because of  

clear

%  delete(gcp('nocreate'))
%  pc = parcluster('local')
%  parpool(pc, 128);
%  spmd rank = labindex;
%      fprintf(1,'Hello from %d\n',rank);
%  end

%fraction (0-1) of 2D obj mask pixels you require to overlap to match-up MCS,MP,LS objects
%objoverlapthresh = 0.0001;

objoverlapthreshs = [0.00001, 0.05, 0.1, 0.25, 0.5 ] ;

for OVERLAPS = 2 : length(objoverlapthreshs)

% OVERLAPS = 1;

    clearvars -except objoverlapthreshs OVERLAPS

    objoverlapthresh = objoverlapthreshs(OVERLAPS);

    disp(['overlap: ',num2str(objoverlapthresh*100)])

    % wanna plot stuff as you go? (1 = yes, 0 = nope)
    plotme = 0;

    %want to recover some pieces of LSs lost in the 'tracknumber' field because of what looks like watershed artifact segmentation?
    iterative_LS_recovery = 1;  %1 to recover, 0 if nah.
    numiterations = 4;  %if iterating, how many iterations. I think 3-4 should just about do it, based ENTRIELY on spot tests rather than rigorous thorough testing

    % range of lat/lon you want to tag a "CONUS-passing-thru" synoptic feature
    latrange =  [30 50];
    lonrange = [-120 -80];

    TRACKVAR = 'VOR600_bpf_sm7pt' ;   %variable that your tracked synoptic objects with in pyflextrkr

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%% data locations and filenames:
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    YRLIST = ['2004';
        '2005';
        '2006';
        '2007';
        '2008';
        '2009';
        '2010';
        '2011';
        '2012';
        '2013';   %10
        '2014';
        '2015';
        '2016';
        '2017';
        '2018';   %15
        '2019';
        '2020';
        '2021'];

    [ay by] = size(YRLIST); clear by

    for  YY = 1:ay

        disp(['overlap: ',num2str(objoverlapthresh*100)])
        % YY = 13 ;

        clearvars -except ay YRLIST TRACKVAR plotme latrange lonrange YY iterative_LS_recovery numiterations objoverlapthreshs OVERLAPS objoverlapthresh


        YYYY = YRLIST(YY,:) ;

        %home:
        rootdir = '/Volumes/LaCie/WACCEM/datafiles/Bandpass/' ;    %root dir location of syn object flextrkr files
        %nersc:
        %rootdir = '/pscratch/sd/j/jmarquis/ERA5_waccem/Bandpassed/';

        mpenvdir = '/Users/marq789/Documents/PROJECTS/WACCEM/MPera5envs/';

        outdir = strcat(rootdir,'/matlab/');

        % sub-SYNOPTIC OBJECTS DEFINITIONS:
        %nersc:
        %     MPtrackdir = strcat(rootdir,'/vortracking/');
        %     MPstatsdir = strcat(rootdir,'/vortstats/');

        %home:
        %     MPtrackdir = strcat(rootdir,'/vortracking_tester/');     %
        %     MPstatsdir = strcat(rootdir,'/vortstats_tester/');

        MPtrackdir = strcat(rootdir,'/vorttracking/');
        MPstatsdir = strcat(rootdir,'/vortstats/');


        MPtrackname = strcat('vorbpf_tracks_morevar',YYYY,'*.nc')  ;  %file name search criteria for synotpic pixel object file search

        %home tester set:
        %MPstatsf = strcat('/trackstats_final_',YYYY,'0501.0000_',YYYY,'0531.2300.nc')  ;   % name convention of synoptic object stats file
        %full set:
        MPstatsf = strcat('/trackstats_final_',YYYY,'0501.0000_',YYYY,'0831.2300.nc')  ;   % name convention of synoptic object stats file

        % LARGE-SCALE-SYNOPTIC OBJECTS DEFINITIONS:

        %nersc:
        %     LStrackdir = strcat(rootdir,'/largescale/vortracking/');     %
        %     LSstatsdir = strcat(rootdir,'/largescale/vortstats/');

        % % home tester:
        %     LStrackdir = strcat(rootdir,'/LARGESCALE_vortracking_tester/');     %
        %     LSstatsdir = strcat(rootdir,'/LARGESCALE_vortstats_tester/');
        LStrackdir = strcat(rootdir,'/LARGESCALE_vorttracking/');     %
        LSstatsdir = strcat(rootdir,'/LARGESCALE_vortstats/');

        LStrackname = strcat('vorbpf_tracks_morevar',YYYY,'*.nc')  ;  %file name search criteria for synotpic pixel object file search

        %full tester:
        LSstatsf = strcat('/trackstats_final_',YYYY,'0501.0000_',YYYY,'0831.2300.nc')  ;   % name convention of synoptic object stats file
        %home tester set:
        %LSstatsf = strcat('/trackstats_final_',YYYY,'0501.0000_',YYYY,'0531.2300.nc')  ;   % name convention of synoptic object stats file



        % MCS OBJECT DEFINITIONS:

        %nersc:
        %MCStracksdir = strcat('/pscratch/sd/f/feng045/usa/gridrad_v3/',YYYY,'/mcstracking/',YYYY,'0101.0000_', num2str(str2num(YYYY)+1), '0101.0000/')  ;   %location of MCS track files
        %home:
        MCStracksdir = '/Volumes/LaCie/WACCEM/datafiles/MCStracks/CONUS/';


        mcstrackf = strcat('mcstrack_',YYYY) ; %file name search criteria for mcs pixel object file search

        %home:
        MCSstatdir = '/Volumes/LaCie/WACCEM/datafiles/MCStracks/CONUS/MCS_track_stats/' ;
        %nersc:
        %MCSstatdir = strcat('/pscratch/sd/f/feng045/usa/gridrad_v3/',YYYY,'/stats/')  ;





        if( str2num(YYYY) == 2004  |  str2num(YYYY) == 2005  |  str2num(YYYY) == 2006  |  str2num(YYYY) == 2007  |  str2num(YYYY) == 2008  |  str2num(YYYY) == 2009 |  ...
                str2num(YYYY) == 2010  |  str2num(YYYY) == 2011  |  str2num(YYYY) == 2012  |  str2num(YYYY) == 2013  |  str2num(YYYY) == 2014  | ...
                str2num(YYYY) == 2015  |  str2num(YYYY) == 2016 | str2num(YYYY) == 2017 )

            %nersc:
            %MCStracksdir = strcat('/pscratch/sd/f/feng045/usa/gridrad_v3/',YYYY,'/mcstracking/',YYYY,'0101.0000_', num2str(str2num(YYYY)+1), '0101.0000/')  ;   %location of MCS track files
            %home:
            MCStracksdir = strcat(MCStracksdir,YYYY,'0101.0000_', num2str(str2num(YYYY)+1), '0101.0000/')  ;

            mcstrackf = strcat('mcstrack_',YYYY) ; %file name search criteria for mcs pixel object file search

            %disp('Old MCS stats files')
            MCSstatsfile = strcat(MCSstatdir,'mcs_tracks_final_',YYYY,'0101.0000_',  num2str(str2num(YYYY)+1) ,'0101.0000.nc')       % name convention of mcs object stats file

        elseif(  str2num(YYYY) == 2018  |  str2num(YYYY) == 2019  |  str2num(YYYY) == 2020  |  str2num(YYYY) == 2021  )

            %nersc:
            %MCStracksdir = strcat('/pscratch/sd/f/feng045/usa/gridrad_v3/',YYYY,'/mcstracking/',YYYY,'0401.0000_', num2str(str2num(YYYY)), '0901.0000/')  ;   %location of MCS track files
            %home:
            %MCStracksdir = strcat(MCStracksdir,YYYY,'0401.0000_', num2str(str2num(YYYY)), '0901.0000/')  ;
            MCStracksdir = strcat(MCStracksdir,YYYY,'0101.0000_', num2str(str2num(YYYY)+1), '0101.0000/')  ;

            mcstrackf = strcat('mcstrack_',YYYY) ; %file name search criteria for mcs pixel object file search

            %disp('New MCS stats files')
            MCSstatsfile = strcat(MCSstatdir,'mcs_tracks_final_',YYYY,'0401.0000_',  num2str(str2num(YYYY)) ,'0901.0000.nc')        % name convention of mcs object stats file

        end


        % ncdisp( '/Volumes/LaCie/WACCEM/datafiles/MCStracks/CONUS/MCS_track_stats/mcs_tracks_final_20210401.0000_20210901.0000.nc')



        %POST_PROCESSING/SAVING DEFINITIIONS:

        % % plots:
        % mkdir(strcat(outdir,'/png/'))
        % fileoutp2 = horzcat(outdir,'/png/VOR600_bpf_sm7pt_MASKED_latlon_',ttpad, '_', char(basetime_met_yymmddhhmmss(TT)),'.png' )  ;    %if you're plotting, how to name the png:


        %save output (.mat):

        matout = strcat(rootdir,'/matlab/',YYYY,'_vorstats_masks_zone_v7b_MatchupEnvs_objoverlap',num2str(objoverlapthresh*100),'percent.mat') ;   %name/location of .mat output save file







        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%    On with the code....
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        disp('    ')
        disp(' ************** Started working on year: ')
        disp( YYYY )
        disp(' **************')
        disp('    ')

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 1) Load synoptic track stuff
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



        % ncdisp('/Volumes/LaCie/WACCEM/datafiles/Bandpass/vorttracking/psitracks_20120630_0900.nc')




        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 1a) FLEXTRKR results: load all of the MP tracks
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        tracklist = ls( horzcat(MPtrackdir,MPtrackname) );
        filelist = split(tracklist);
        [sa sb] = size(filelist); clear sb;


        %for reference array sizes
        dummy = ncread(char(filelist(1)),'tracknumber');
        [aa bb] = size(dummy);

        %seed data arrays:
        basetime_MPtracks = zeros(sa-1); basetime_MPtracks = basetime_MPtracks(:,1);
        tracknumber_MPtracks = zeros(aa,bb,sa-1);
        MP600 = zeros(aa,bb,sa-1);
        %seed extra variables:
        U600 = zeros(aa,bb,sa-1);          %'raw' era5 u,v @ 600mb
        V600 = zeros(aa,bb,sa-1);
        U600_bpf = zeros(aa,bb,sa-1);          %'raw' era5 u,v @ 600mb
        V600_bpf = zeros(aa,bb,sa-1);
        W600 = zeros(aa,bb,sa-1);
        W600_bpf = zeros(aa,bb,sa-1);      %band-pass filtered omega @ 600mb
        %     PW = zeros(aa,bb,sa-1);            %'raw' era5 PW
        %     e5CAPE = zeros(aa,bb,sa-1);            %'raw' era5 cape
        %     e5WVD = zeros(aa,bb,sa-1);            %'raw' era5 vert integ wv div


        %load lat/lon fields:
        lat_MPtracks = ncread(char(filelist(1)),'lat');
        lon_MPtracks = ncread(char(filelist(1)),'lon');
        lat2d = ncread(char(filelist(1)),'latitude');
        lon2d = ncread(char(filelist(1)),'longitude');
        lon_met = lon_MPtracks;
        lat_met = lat_MPtracks;

        %populate data fields:
        disp('   ')
        disp('populating MP track info from  ')
        disp(horzcat(MPtrackdir,MPtrackname))
        disp('   ')
        disp(' Tracked variable is:  ')
        disp(TRACKVAR)

        tic
        parfor h = 1:sa-1

            filname = char(filelist(h)) ;

            % ncdisp(filname)

            basetime_MPtracks(h) = ncread(filname,'base_time');
            tracknumber_MPtracks(:,:,h) = ncread(filname,'tracknumber');
            MP600(:,:,h) = ncread(filname,TRACKVAR);
            cloudtracknumber_MPtracks(:,:,h) = ncread(filname,'cloudtracknumber');  % I end up using this one and manually filtering mergers/splits out (not included in tracknumber)

            U600(:,:,h) = ncread(filname,'U600');
            V600(:,:,h) = ncread(filname,'V600');
            U600_bpf(:,:,h) = ncread(filname,'U600_bpf');
            V600_bpf(:,:,h) = ncread(filname,'V600_bpf');  
            W600(:,:,h) = ncread(filname,'W600');
            W600_bpf(:,:,h) = ncread(filname,'W600_bpf');
            %PW(:,:,h) = ncread(filname,'PW');
            %e5CAPE(:,:,h) = ncread(filname,'CAPE');
            %e5WVD(:,:,h) = ncread(filname,'VIWVD');

            %tracknumber(:,:,h) = ncread(filname,'tracknumber');
            %trackstatus = ncread(filname,'track_status');
            %featurenumber = ncread(filname,'feature_number');
            %merge_tracknumber = ncread(filname,'merge_tracknumber');
            %split_tracknumber = ncread(filname,'split_tracknumber');

        end
        toc %~200-300 sec
        disp('   ')

        basetime_met_yymmddhhmmss = datetime(basetime_MPtracks, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') ;







        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 1b) FLEXTRKR results: load basic MP track stats level stuff:
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        MPstatsfile = strcat(MPstatsdir,MPstatsf);

        %   ncdisp(MPstatsfile)

        basetime_MPstats = ncread(MPstatsfile,'base_time');
        times_MPstats = ncread(MPstatsfile,'times');
        tracks_MPstats = ncread(MPstatsfile,'tracks');

        meanlat_MPstats = ncread(MPstatsfile,'meanlat');
        meanlon_MPstats = ncread(MPstatsfile,'meanlon');
        area_MPstats = ncread(MPstatsfile,'area');
        duration_MPstats = ncread(MPstatsfile,'track_duration');
        tracknum_MPstats = ncread(MPstatsfile,'cloudnumber');
        status_MPstats = ncread(MPstatsfile,'track_status');

        end_merge_MPstats = ncread(MPstatsfile,'end_merge_cloudnumber');
        start_split_MPstats = ncread(MPstatsfile,'start_split_cloudnumber');

        startstatus_MPstats = ncread(MPstatsfile,'start_status');
        endstatus_MPstats = ncread(MPstatsfile,'end_status');

        basetime_MPstats_met_yymmddhhmmss = datetime(basetime_MPstats, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') ;




        %%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%% load AFWA & kinematic environmental data from within MP mask:
        %%%%%%%%%%%%%%%%%%%%%%
       % afwainfile = [mpenvdir,'mp_tracks_era5_afwa_',YRLIST(YY,:),'0501.0000_',YRLIST(YY,:),'0831.2300.nc'] ;

        if(YY == 11)             %pending: 2014    %%%% 2014 times out at 24 hours wallclock! Ugh, will probably have to spli
        %dont log anything beyond NANs
%         meanMUCAPE_MPstats_ALLYRS(:,:,yr) = NaN;
%         maxMUCAPE_MPstats_ALLYRS(:,:,yr) = NaN;
%         meanMUCIN_MPstats_ALLYRS(:,:,yr) = NaN;
%         minMUCIN_MPstats_ALLYRS(:,:,yr) = NaN;
%         meanMULFC_MPstats_ALLYRS(:,:,yr) = NaN;
%         meanMUEL_MPstats_ALLYRS(:,:,yr) = NaN;
%         meanPW_MPstats_ALLYRS(:,:,yr) = NaN;
%         maxPW_MPstats_ALLYRS(:,:,yr) = NaN;
%         minPW_MPstats_ALLYRS(:,:,yr) = NaN;

            %piecewise fix:
            afwainfile = [mpenvdir,'/piecewise/AFWA_',num2str(YRLIST(YY,:)),'_piecewise.nc'] ;
            %dum = ncread( afwainfile, 'meanMUCAPE' )  ; [tims tracks] = size(dum);
            %tracks = tracks(end)+1 ; %stupid zero index!
    
            meanMUCAPE_MPstats  = ncread(afwainfile,'meanMUCAPE');
            maxMUCAPE_MPstats  = ncread(afwainfile,'maxMUCAPE');
            meanMUCIN_MPstats  = ncread(afwainfile,'meanMUCIN');
            minMUCIN_MPstats  = ncread(afwainfile,'minMUCIN');
            meanMULFC_MPstats  = ncread(afwainfile,'meanMULFC');
            meanMUEL_MPstats  = ncread(afwainfile,'meanMUEL');
            meanPW_MPstats  = ncread(afwainfile,'meanPW');
            maxPW_MPstats  = ncread(afwainfile,'maxPW');
            minPW_MPstats  = ncread(afwainfile,'minPW');
        else
            afwainfile = [mpenvdir,'mp_tracks_era5_afwa_',YRLIST(YY,:),'0501.0000_',YRLIST(YY,:),'0831.2300.nc'] ;
            meanMUCAPE_MPstats  = ncread(afwainfile,'meanMUCAPE');
            maxMUCAPE_MPstats   = ncread(afwainfile,'maxMUCAPE');
            meanMUCIN_MPstats   = ncread(afwainfile,'meanMUCIN');
            minMUCIN_MPstats    = ncread(afwainfile,'minMUCIN');
            meanMULFC_MPstats   = ncread(afwainfile,'meanMULFC');
            meanMUEL_MPstats    = ncread(afwainfile,'meanMUEL');
            meanPW_MPstats      = ncread(afwainfile,'meanPW');
            maxPW_MPstats       = ncread(afwainfile,'maxPW');
            minPW_MPstats       = ncread(afwainfile,'minPW');
        end

% %diagnostic
%         meanPW_MPstats_0v7 = meanPW_MPstats;
%         save('test_rawPWv7.mat','meanPW_MPstats_0v7')
%         load('test_rawPWv6.mat','meanPW_MPstats_0v6')
%         length(find(isnan(meanPW_MPstats_0v7(1,:))==0))
%         length(find(isnan(meanPW_MPstats_0v6(1,:))==0))

       
        if( YY==2 | YY==9 | YY==11 | YY==13 ) %pending: 2014    %%%% 2014 times out at 24 hours wallclock! Ugh, will probably have to spli
%             meanshearmag0to2_MPstats = area_MPstats;    meanshearmag0to2_MPstats(:) = NaN;
%             maxshearmag0to2_MPstats = area_MPstats;     maxshearmag0to2_MPstats(:) = NaN;
%             meanshearmag0to6_MPstats = area_MPstats;    meanshearmag0to6_MPstats(:) = NaN;
%             maxshearmag0to6_MPstats = area_MPstats;     maxshearmag0to6_MPstats(:) = NaN;
%             meanshearmag2to9_MPstats = area_MPstats;    meanshearmag2to9_MPstats(:) = NaN;
%             maxshearmag2to9_MPstats = area_MPstats;     maxshearmag2to9_MPstats(:) = NaN;
%             meanOMEGA600_MPstats = area_MPstats;        meanOMEGA600_MPstats(:) = NaN;
%             minOMEGA600_MPstats = area_MPstats;         minOMEGA600_MPstats(:) = NaN;
%             minOMEGAsub600_MPstats = area_MPstats;      minOMEGAsub600_MPstats(:) = NaN;
%             meanVIWVD_MPstats = area_MPstats;           meanVIWVD_MPstats(:) = NaN;
%             minVIWVD_MPstats = area_MPstats;            minVIWVD_MPstats(:) = NaN;
%             maxVIWVD_MPstats = area_MPstats;            maxVIWVD_MPstats(:) = NaN;
%             meanDIV750_MPstats = area_MPstats;          meanDIV750_MPstats(:) = NaN;
%             minDIV750_MPstats = area_MPstats;           minDIV750_MPstats(:) = NaN;
%             minDIVsub600_MPstats = area_MPstats;        minDIVsub600_MPstats(:) = NaN;
            dyninfile = [mpenvdir,'/piecewise/KINEM_',num2str(YRLIST(YY,:)),'_piecewise.nc'] ;
            %dum = ncread( dyninfile, 'meanWNDSPD600' )  ; [tims tracks] = size(dum);
            %tracks = tracks(end)+1 ; %stupid zero index!
    
            meanshearmag0to2_MPstats = ncread(dyninfile,'meanshearmag0to2');
            maxshearmag0to2_MPstats = ncread(dyninfile,'maxshearmag0to2');
            meanshearmag0to6_MPstats = ncread(dyninfile,'meanshearmag0to6');
            maxshearmag0to6_MPstats = ncread(dyninfile,'maxshearmag0to6');
            meanshearmag2to9_MPstats = ncread(dyninfile,'meanshearmag2to9');
            maxshearmag2to9_MPstats = ncread(dyninfile,'maxshearmag2to9');
            meanOMEGA600_MPstats = ncread(dyninfile,'meanOMEGA600');
            minOMEGA600_MPstats = ncread(dyninfile,'minOMEGA600');
            minOMEGAsub600_MPstats = ncread(dyninfile,'minOMEGAsub600');
            meanVIWVD_MPstats = ncread(dyninfile,'meanVIWVD');
            minVIWVD_MPstats = ncread(dyninfile,'minVIWVD');
            maxVIWVD_MPstats = ncread(dyninfile,'maxVIWVD');
            meanDIV750_MPstats = ncread(dyninfile,'meanDIV750');
            minDIV750_MPstats = ncread(dyninfile,'minDIV750');
            minDIVsub600_MPstats = ncread(dyninfile,'minDIVsub600');
        else
            KINinfile = [mpenvdir,'mp_tracks_era5_Dyn_',YRLIST(YY,:),'0501.0000_',YRLIST(YY,:),'0831.2300.nc'] ;
            meanshearmag0to2_MPstats    = ncread(KINinfile,'meanshearmag0to2');
            maxshearmag0to2_MPstats     = ncread(KINinfile,'maxshearmag0to2');
            meanshearmag0to6_MPstats    = ncread(KINinfile,'meanshearmag0to6');
            maxshearmag0to6_MPstats     = ncread(KINinfile,'maxshearmag0to6');
            meanshearmag2to9_MPstats    = ncread(KINinfile,'meanshearmag2to9');
            maxshearmag2to9_MPstats     = ncread(KINinfile,'maxshearmag2to9');
            meanOMEGA600_MPstats    = ncread(KINinfile,'meanOMEGA600');
            minOMEGA600_MPstats     = ncread(KINinfile,'minOMEGA600');
            minOMEGAsub600_MPstats  = ncread(KINinfile,'minOMEGAsub600');
            meanVIWVD_MPstats       = ncread(KINinfile,'meanVIWVD');
            minVIWVD_MPstats        = ncread(KINinfile,'minVIWVD');
            maxVIWVD_MPstats        = ncread(KINinfile,'maxVIWVD');
            meanDIV750_MPstats      = ncread(KINinfile,'meanDIV750');
            minDIV750_MPstats       = ncread(KINinfile,'minDIV750');
            minDIVsub600_MPstats    = ncread(KINinfile,'minDIVsub600');
        end

        
        if( YY==2 | YY==9 | YY==11 | YY==13 ) %pending: 2014    %%%% 2014 times out at 24 hours wallclock! Ugh, will probably have to spli
%             meanWNDSPD600 = area_MPstats;    meanWNDSPD600(:) = NaN;
%             meanWNDDIR600 = area_MPstats;    meanWNDDIR600(:) = NaN;
            dyninfile = [mpenvdir,'/piecewise/KINEM_',num2str(YRLIST(YY,:)),'_piecewise.nc'] ;
            meanWNDSPD600  = ncread(dyninfile,'meanWNDSPD600');    
            meanWNDDIR600  = ncread(dyninfile,'meanWNDDIR600');  
        else
            wininfile = [mpenvdir,'mp_tracks_era5_win_',YRLIST(YY,:),'0501.0000_',YRLIST(YY,:),'0831.2300.nc'] ;
            meanWNDSPD600   =   ncread(wininfile,'meanWNDSPD600');
            meanWNDDIR600   =   ncread(wininfile,'meanWNDDIR600');
        end








        % %% %% %% %% %% %% %% %
        % % calculate some derivative stat quantities:
        % %% %% %% %% %% %% %% %

        %synoptic feature instantaneous d(AREA)/dt:
        disp('   ')
        disp(' calculating MP ob dAdt ')
        [saa sbb] = size(area_MPstats);
        dAdt_MPstats = area_MPstats;  dAdt_MPstats(:) = NaN;
        tic
        for t = 2:saa-1;
            for n = 1:sbb
                dAdt_MPstats(t,n) = ( area_MPstats(t+1,n) - area_MPstats(t-1,n) )/( (t+1) - (t-1) );   %km2/hr
            end
        end
        toc
        disp('   ')


        % % commenting this out for nersc running because I dont think they have "distance" toolbox
        % calculate motion of synoptic objects:

        % First convert lat/lon to x,y relative to a centralish point of CONUS.
        % This could get a bit iffy as calculated over large (CONUS) area, so I will center it on the mean lat/long of each track:
        X_MPstats = single(area_MPstats); X_MPstats(:) = NaN;
        Y_MPstats = single(area_MPstats); Y_MPstats(:) = NaN;
        disp('   ')
        disp(' calculate x,y of MP object ')
        tic
        parfor t = 1:saa-1
            for n = 1:sbb
                CENlat = mean(meanlat_MPstats(:,n),'omitnan')     ;
                CENlon = mean(meanlon_MPstats(:,n),'omitnan')-360 ;
                az =[];
                arclen =[];
                distkm = [];
                [arclen,az] = distance(CENlat,CENlon,meanlat_MPstats(t,n),meanlon_MPstats(t,n));
                distkm = deg2km(arclen);
                [y_MPstats,x_MPstats] = pol2cart(deg2rad(az),distkm);
                X_MPstats(t,n) = x_MPstats ;
                Y_MPstats(t,n) = y_MPstats ;
                y_MPstats =[];
                x_MPstats =[];
            end
        end
        toc  % ~ 78 sec
        disp('   ')

        % calculate object motions:
        MotionX_MPstats = single(area_MPstats); MotionX_MPstats(:) = NaN;
        MotionY_MPstats = single(area_MPstats); MotionY_MPstats(:) = NaN;
        disp('   ')
        disp('calc syn obj motion')
        tic
        for t = 2:saa-1
            for n = 1:sbb
                MotionX_MPstats(t,n) = ( X_MPstats(t+1,n) - X_MPstats(t-1,n) )/( (t+1) - (t-1) ) * (1000/3600);   % m/s
                MotionY_MPstats(t,n) = ( Y_MPstats(t+1,n) - Y_MPstats(t-1,n) )/( (t+1) - (t-1) ) * (1000/3600);   % m/s
            end
        end
        toc  % ~ 1 sec
        disp('   ')


        % % diagnostic plot:
        % scatter(meanlon_MPstats(:)-360, meanlat_MPstats(:), 10, x_MPstats(:), "filled")
        % scatter(meanlon_MPstats(:)-360, meanlat_MPstats(:), 10, y_MPstats(:), "filled")







        % catalog vorticity values associated with synoptic feature:
        maxVOR600_MPstats = area_MPstats; maxVOR600_MPstats(:) = NaN;

        % NEED: cloudtracknumber_MPtracks * MP600;  % basetime_MPtracks = basetime_mcsstats
        disp('   ')
        disp('catalog vorticity values associated with synoptic feature')
        tic
        for t_met = 1:sa-1

            %t_met = 21;

            bt_met = basetime_MPtracks(t_met);

            masked_VOR600 = MP600(:,:,t_met);
            masked_VOR600(isnan( cloudtracknumber_MPtracks(:,:,t_met) ))  = NaN;

            curr_MPfeatures = unique(cloudtracknumber_MPtracks(:,:,t_met)); curr_MPfeatures(isnan(curr_MPfeatures)) = [];

            %loop through syn_features and catalog the max
            for n = 1:length(curr_MPfeatures)

                %%%%%%%%% pick up here testing if it is grabbing the right vor max data from the current scene
                max_maskvor = max( masked_VOR600(  find(cloudtracknumber_MPtracks(:,:,t_met) == curr_MPfeatures(n))  ) );  % max of vorticity at all pts in a synoptic mask at current time

                %now place this in the maxVOR600_MPstats array by finding the syn object basetime:
                maxVOR600_MPstats(  find( basetime_MPstats(:,curr_MPfeatures(n)) == bt_met) , curr_MPfeatures(n) ) = max_maskvor ;

            end

        end
        toc    %12 sec
        disp('   ')

        % %diagnostics:
        % t_met = 21;
        % basetime_met_yymmddhhmmss(t_met);
        % masked_VOR600 = MP600(:,:,t_met);
        % masked_VOR600(isnan( cloudtracknumber_MPtracks(:,:,t_met) ))  = NaN;
        % figure; contourf( masked_VOR600 , 30    )
        % figure; contourf( cloudtracknumber_MPtracks(:,:,t_met), 30    )
        % bt_met = basetime_MPtracks(t_met);











        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 2a) FLEXTRKR results: load all of the LS tracks
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        tracklist = ls( horzcat(LStrackdir,LStrackname) );
        filelist = split(tracklist);
        [sa sb] = size(filelist); clear sb;


        %for reference array sizes
        dummy = ncread(char(filelist(1)),'tracknumber');
        [aa bb] = size(dummy);
        clear dummy

        %seed data arrays:
        basetime_LStracks = zeros(sa-1); basetime_LStracks = basetime_LStracks(:,1);
        tracknumber_LStracks = zeros(aa,bb,sa-1);
        LS600 = zeros(aa,bb,sa-1);
        %seed extra variables:
        %     U600 = zeros(aa,bb,sa-1);          %'raw' era5 u,v @ 600mb
        %     V600 = zeros(aa,bb,sa-1);
        %     W600 = zeros(aa,bb,sa-1);
        %     W600_bpf = zeros(aa,bb,sa-1);      %band-pass filtered omega @ 600mb

        %load lat/lon fields:
        lat_LStracks = ncread(char(filelist(1)),'lat');
        lon_LStracks = ncread(char(filelist(1)),'lon');
        lat2d = ncread(char(filelist(1)),'latitude');
        lon2d = ncread(char(filelist(1)),'longitude');
        lon_met = lon_LStracks;
        lat_met = lat_LStracks;

        %populate data fields:
        disp('   ')
        disp('populating LS track info from  ')
        disp(horzcat(LStrackdir,LStrackname))
        disp('   ')
        disp(' Tracked variable is:  ')
        disp(TRACKVAR)

        tic
        parfor h = 1:sa-1

            filname = char(filelist(h)) ;

            % ncdisp(filname)

            basetime_LStracks(h) = ncread(filname,'base_time');
            tracknumber_LStracks(:,:,h) = ncread(filname,'tracknumber');
            LS600(:,:,h) = ncread(filname,TRACKVAR);
            cloudtracknumber_LStracks(:,:,h) = ncread(filname,'cloudtracknumber');  %will use this for now because it includes all (segmented) pieces of masks that might be being broken up by both merge/splits but also watershed detection. tracknumber kills watershed segmented pieces and merger/splits (I want to keep the watershed pieces)

            %         U600(:,:,h) = ncread(filname,'U600');
            %         V600(:,:,h) = ncread(filname,'V600');
            %         W600(:,:,h) = ncread(filname,'W600');
            %         W600_bpf(:,:,h) = ncread(filname,'W600_bpf');
            %         PW(:,:,h) = ncread(filname,'PW');
            %         e5CAPE(:,:,h) = ncread(filname,'CAPE');
            %         e5WVD(:,:,h) = ncread(filname,'VIWVD');

            %tracknumber(:,:,h) = ncread(filname,'tracknumber');
            %trackstatus = ncread(filname,'track_status');
            %featurenumber = ncread(filname,'feature_number');
            %merge_tracknumber = ncread(filname,'merge_tracknumber');
            %split_tracknumber = ncread(filname,'split_tracknumber');

        end
        toc %100 sec
        disp('   ')

        basetime_LS_yymmddhhmmss = datetime(basetime_LStracks, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') ;




        %%%%%%%%%%
        % bonus QC on the track mask fields to recover parts of LSs that are lost to flood-fill-ectomy
        %%%%%%%%%%%

        if(iterative_LS_recovery == 1)

            FINALRECOVERY_LS = tracknumber_LStracks;
            bloater = strel("disk",4);  %bloating kernel

            %iterative. I do this because I only add one portion of the watershed-ectomied LS masks back at a time.
            % So, iterating at least 2 times should recover many/most segmented pieces. More than 2 should do even better.
            % I havnt tested what the upper limit should be, but based on spot tests, 3-4 should get most(/all?)

            for Nit = 1:numiterations

                tic
                for TT = 1:sa-1

                    if(Nit ==1)
                        tn = tracknumber_LStracks(:,:,TT);
                    else
                        tn = FINALRECOVERY_LS(:,:,TT);
                    end

                    %all trimmed LS masks in current scene
                    ALLcurrLS = unique(tn); ALLcurrLS(isnan(ALLcurrLS))=[];

                    %loop over ALLcurrLS here
                    for L = 1:numel(ALLcurrLS)
                        tnn = tn;
                        %all parts of LSs in current scene
                        ctn = cloudtracknumber_LStracks(:,:,TT);
                        ctn(isnan(ctn)) = 0; %convert nans to zero
                        currLS = ALLcurrLS(L);  %current targeted LS object
                        ctn(ctn ~= currLS) = 0;  %kill all objs in full LS scene that arent the current
                        partmask = find(tn == currLS) ; %where full and clipped tracks overlap
                        ctn(partmask) = 0;  %zero-out the part in cloudtracknum field containing the already good part of the LS

                        %if there are LS pieces to recover:
                        if( isempty( find(ctn ~= 0) ) == 0 )

                            %binary-ify the tracknum field
                            tnn(tnn ~= currLS) = 0;
                            tnn(isnan(tnn)) = 0;
                            tnn(tnn == currLS) = 1;

                            %bloat currLS in tracknum field and floodfill in the overlapping part of the cloudtracknum field
                            tnbloat = imdilate(tnn,bloater) ;
                            [overlapI overlapJ] = find(tnbloat == 1 & ctn == currLS);
                            if( isempty(overlapI)==0 )
                                recoveredpiece_LS = bwselect(ctn,overlapJ(1),overlapI(1),4); %flood-filled part of LS to recover
                                [irec jrec] = find(recoveredpiece_LS == 1);
                                for ii = 1:numel(irec)
                                    FINALRECOVERY_LS(irec(ii),jrec(ii),TT) = currLS;
                                end
                            end
                        end
                    end  %currLS loop

                end  %time
                toc   %~ 10--20 sec

                %diagnostic fields
                %         if(Nit==1)
                %             FINALRECOVERY_LS1 = FINALRECOVERY_LS;
                %         elseif(Nit==2)
                %             FINALRECOVERY_LS2 = FINALRECOVERY_LS;
                %         elseif(Nit==3)
                %             FINALRECOVERY_LS3 = FINALRECOVERY_LS;
            end

        end % Niterations

        % redefine whatever var you use later for LS tracks
        cloudtracknumber_LStracks = FINALRECOVERY_LS;

        clear FINALRECOVERY_LS

        %end %do the iterative recovery?

        % %diagnostic plots
        % tt = 49 ;
        % figure; contourf(tracknumber_LStracks(:,:,tt),20)
        % figure; contourf(cloudtracknumber_LStracks(:,:,tt),20)
        % %figure; contourf(FINALRECOVERY_LS(:,:,tt),20)
        % figure; contourf(FINALRECOVERY_LS1(:,:,tt),20)
        % figure; contourf(FINALRECOVERY_LS2(:,:,tt),20)
        % figure; contourf(FINALRECOVERY_LS3(:,:,tt),20)








        % %serial version, 1 iteration works

        % FINALRECOVERY_LS = tracknumber_LStracks;
        % bloater = strel("disk",10);  %bloating kernel
        %
        % tic
        % for TT = 1:sa-1
        %     tn = tracknumber_LStracks(:,:,TT);
        %
        %     %all trimmed LS masks in current scene
        %     ALLcurrLS = unique(tn); ALLcurrLS(isnan(ALLcurrLS))=[];
        %
        %     %loop over ALLcurrLS here
        %     for L = 1:numel(ALLcurrLS)
        %         tnn = tn;
        %         %all parts of LSs in current scene
        %         ctn = cloudtracknumber_LStracks(:,:,TT);
        %         ctn(isnan(ctn)) = 0; %convert nans to zero
        %         currLS = ALLcurrLS(L);  %current targeted LS object
        %         ctn(ctn ~= currLS) = 0;  %kill all objs in full LS scene that arent the current
        %         partmask = find(tn == currLS) ; %where full and clipped tracks overlap
        %         ctn(partmask) = 0;  %zero-out the part in cloudtracknum field containing the already good part of the LS
        %
        %         %if there are LS pieces to recover:
        %         if( isempty( find(ctn ~= 0) ) == 0 )
        %
        %             %binary-ify the tracknum field
        %             tnn(tnn ~= currLS) = 0;
        %             tnn(isnan(tnn)) = 0;
        %             tnn(tnn == currLS) = 1;
        %
        %             %bloat currLS in tracknum field and floodfill in the overlapping part of the cloudtracknum field
        %             tnbloat = imdilate(tnn,bloater) ;
        %             [overlapI overlapJ] = find(tnbloat == 1 & ctn == currLS);
        %             if( isempty(overlapI)==0 )
        %                 recoveredpiece_LS = bwselect(ctn,overlapJ(1),overlapI(1),4); %flood-filled part of LS to recover
        %                 [irec jrec] = find(recoveredpiece_LS == 1);
        %                 for ii = 1:numel(irec)
        %                     FINALRECOVERY_LS(irec(ii),jrec(ii),TT) = currLS;
        %                 end
        %             end
        %         end
        %     end  %currLS loop
        %
        % end  %time
        % toc   %~ 20 sec
        %
        % % tt = 249 ;
        % % figure; contourf(tracknumber_LStracks(:,:,tt),20)
        % % figure; contourf(cloudtracknumber_LStracks(:,:,tt),20)
        % % figure; contourf(FINALRECOVERY_LS(:,:,tt),20)













        %   figure;  contourf(W600(:,:,30),30)


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 2b) FLEXTRKR results: load basic LS track stats level stuff:
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        LSstatsfile = strcat(LSstatsdir,LSstatsf);

        %   ncdisp(LSstatsfile)

        basetime_LSstats = ncread(LSstatsfile,'base_time');
        times_LSstats = ncread(LSstatsfile,'times');
        tracks_LSstats = ncread(LSstatsfile,'tracks');

        meanlat_LSstats = ncread(LSstatsfile,'meanlat');
        meanlon_LSstats = ncread(LSstatsfile,'meanlon');
        area_LSstats = ncread(LSstatsfile,'area');
        duration_LSstats = ncread(LSstatsfile,'track_duration');
        tracknum_LSstats = ncread(LSstatsfile,'cloudnumber');
        status_LSstats = ncread(LSstatsfile,'track_status');

        end_merge_LSstats = ncread(LSstatsfile,'end_merge_cloudnumber');
        start_split_LSstats = ncread(LSstatsfile,'start_split_cloudnumber');

        startstatus_LSstats = ncread(LSstatsfile,'start_status');
        endstatus_LSstats = ncread(LSstatsfile,'end_status');

        basetime_LSstats_met_yymmddhhmmss = datetime(basetime_LSstats, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') ;


        % % calculate some derivative stat quantities:


        %synoptic feature instantaneous d(AREA)/dt:
        disp('   ')
        disp(' calculating LS ob dAdt ')
        [saa sbb] = size(area_LSstats);
        dAdt_LSstats = area_LSstats;  dAdt_LSstats(:) = NaN;
        tic
        for t = 2:saa-1;
            for n = 1:sbb
                dAdt_LSstats(t,n) = ( area_LSstats(t+1,n) - area_LSstats(t-1,n) )/( (t+1) - (t-1) );   %km2/hr
            end
        end
        toc
        disp('   ')



        %%% commenting because nersc doesnt have distance toolbox
        % calculate motion of LS objects:
        % First convert lat/lon to x,y relative to a centralish point of CONUS.
        % This could get a bit iffy as calculated over large (CONUS) area, so I will center it on the mean lat/long of each track:
        X_LSstats = single(area_LSstats); X_LSstats(:) = NaN;
        Y_LSstats = single(area_LSstats); Y_LSstats(:) = NaN;
        disp('   ')
        disp(' calculate x,y of MP object ')
        tic
        parfor t = 1:saa-1
            for n = 1:sbb
                CENlat = mean(meanlat_LSstats(:,n),'omitnan')     ;
                CENlon = mean(meanlon_LSstats(:,n),'omitnan')-360 ;
                az =[];
                arclen =[];
                distkm = [];
                [arclen,az] = distance(CENlat,CENlon,meanlat_LSstats(t,n),meanlon_LSstats(t,n));
                distkm = deg2km(arclen);
                [y_LSstats,x_LSstats] = pol2cart(deg2rad(az),distkm);
                X_LSstats(t,n) = x_LSstats ;
                Y_LSstats(t,n) = y_LSstats ;
                y_LSstats =[];
                x_LSstats =[];
            end
        end
        toc  % ~ 78 sec
        disp('   ')

        % calculate object motions:
        MotionX_LSstats = single(area_LSstats); MotionX_LSstats(:) = NaN;
        MotionY_LSstats = single(area_LSstats); MotionY_LSstats(:) = NaN;
        disp('   ')
        disp('calc LS obj motion')
        tic
        for t = 2:saa-1
            for n = 1:sbb
                MotionX_LSstats(t,n) = ( X_LSstats(t+1,n) - X_LSstats(t-1,n) )/( (t+1) - (t-1) ) * (1000/3600);   % m/s
                MotionY_LSstats(t,n) = ( Y_LSstats(t+1,n) - Y_LSstats(t-1,n) )/( (t+1) - (t-1) ) * (1000/3600);   % m/s
            end
        end
        toc  % ~ 1 sec
        disp('   ')


        % % diagnostic plot:
        % scatter(meanlon_MPstats(:)-360, meanlat_MPstats(:), 10, x_MPstats(:), "filled")
        % scatter(meanlon_MPstats(:)-360, meanlat_MPstats(:), 10, y_MPstats(:), "filled")




        % catalog vorticity values associated with synoptic feature:
        maxVOR600_LSstats = area_LSstats; maxVOR600_LSstats(:) = NaN;

        % NEED: cloudtracknumber_MPtracks * MP600;  % basetime_MPtracks = basetime_mcsstats
        disp('   ')
        disp('catalog vorticity values associated with LS feature')
        tic
        for t_met = 1:sa-1

            %t_met = 21;

            bt_met = basetime_LStracks(t_met);

            masked_VOR600 = LS600(:,:,t_met);
            masked_VOR600(isnan( cloudtracknumber_LStracks(:,:,t_met) ))  = NaN;

            curr_LSfeatures = unique(cloudtracknumber_LStracks(:,:,t_met)); curr_LSfeatures(isnan(curr_LSfeatures)) = [];

            %loop through LS_features and catalog the max
            for n = 1:length(curr_LSfeatures)

                %%%%%%%%% pick up here testing if it is grabbing the right vor max data from the current scene
                max_maskvor = max( masked_VOR600(  find(cloudtracknumber_LStracks(:,:,t_met) == curr_LSfeatures(n))  ) );  % max of vorticity at all pts in a synoptic mask at current time

                %now place this in the maxVOR600_MPstats array by finding the LS object basetime:
                maxVOR600_LSstats(  find( basetime_LSstats(:,curr_LSfeatures(n)) == bt_met) , curr_LSfeatures(n) ) = max_maskvor ;

            end

        end
        toc    %12 sec
        disp('   ')



















        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 3) Now load MCS stuff
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 3a) Load MCS tracks/masks
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % MCStracksdir =
        % '/Users/marq789/Documents/PROJECTS/WACCEM/ERA5/MCStracks/CONUS/20120101_20121231/';
        %  %now defined above

        MCSlist = [];

        clear MCS_statslist_permonth


        %may
        MCS_statslist_permonth = ls( horzcat(MCStracksdir , strcat(mcstrackf,'05*.nc') ) ) ;
        mm = split(MCS_statslist_permonth);
        mm = mm(1:end-1);
        MCSlist = vertcat(MCSlist,mm);

        %june
        clear MCS_statslist_permonth
        MCS_statslist_permonth = ls( horzcat(MCStracksdir , strcat(mcstrackf,'06*.nc') ) ) ;
        mm = split(MCS_statslist_permonth);
        mm = mm(1:end-1);
        MCSlist = vertcat(MCSlist,mm);

        %july
        clear MCS_statslist_permonth
        MCS_statslist_permonth = ls( horzcat(MCStracksdir , strcat(mcstrackf,'07*.nc') ) ) ;
        mm = split(MCS_statslist_permonth);
        mm = mm(1:end-1);
        MCSlist = vertcat(MCSlist,mm);

        %august
        clear MCS_statslist_permonth
        MCS_statslist_permonth = ls( horzcat(MCStracksdir , strcat(mcstrackf,'08*.nc') ) ) ;
        mm = split(MCS_statslist_permonth);
        mm = mm(1:end-1);
        MCSlist = vertcat(MCSlist,mm);


        % % % MCSlist = split(MCSstatslist);







        %for reference array sizes:
        dummy = ncread(char(MCSlist(1)),'cloudnumber');
        [aa bb] = size(dummy)



        cc = length(MCSlist);
        %%%%% TEMPORARY LAPTOP BYPASS - go back to length(MCSlist) when using desktop again:
        %    cc = 739;



        %load lat/lon fields:
        lat_mcs = ncread(char(MCSlist(1)),'lat');
        lon_mcs = ncread(char(MCSlist(1)),'lon');

        %seed data fields:
        refl_mcs = zeros(aa,bb,cc);
        mask_mcs = zeros(aa,bb,cc);
        basetime_mcs = zeros(cc); basetime_mcs = basetime_mcs(:,1);
        cloudtracknumber_mcs = zeros(aa,bb,cc);
        %cloudnumber_mcs = zeros(aa,bb,cc);
        %csa_mcs = zeros(aa,bb,cc);
        %pftracknumber_mcs = zeros(aa,bb,cc);

        %populate data arrays:
        disp('   ')
        disp('loading mcs tracks from ')
        disp(horzcat(MCStracksdir , strcat(mcstrackf,'*.nc')))
        tic
        %for n = 1:cc
        parfor n = 1:cc

            filname = char(MCSlist(n));
            %  ncdisp(filname)
            %  ncdisp('/Volumes/LaCie/WACCEM/datafiles/MCStracks/CONUS/20170101.0000_20180101.0000/mcstrack_20170501_0000.nc')

            %cn = ncread(filname,'cloudnumber') ;
            ctn = ncread(filname,'cloudtracknumber') ;
            refl = ncread(filname,'reflectivity_comp') ;
            bt = ncread(filname,'base_time') ;
            %csa = ncread(filname,'csa') ;
            %pf_tn = ncread(filname,'pftracknumber') ;

            %cloudnumber_mcs(:,:,n) = cn;
            cloudtracknumber_mcs(:,:,n) = ctn;
            refl_mcs(:,:,n) = refl;
            basetime_mcs(n) = bt;
            %csa_mcs(:,:,n) = csa;
            %pftracknumber_mcs(:,:,n) = pf_tn;

        end
        toc  % ~ 100-300 sec

        clear ctn refl bt



        %convert to normal human time:
        basetime_mcs_yymmddhhmmss = datetime(basetime_mcs, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') ;





        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 2a) Load MCS stats
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %MCSstatdir = '/Users/marq789/Documents/PROJECTS/WACCEM/ERA5/MCStracks/CONUS/MCS_track_stats/';
        %MCSstatsfile = strcat(MCSstatdir,'mcs_tracks_final_20120101.0000_20130101.0000.nc');

        %    ncdisp(MCSstatsfile)  ;
        %  ncdisp('/Volumes/LaCie/WACCEM/datafiles/MCStracks/CONUS/20170101.0000_20180101.0000/mcstrack_20170501_0000.nc')

        basetime_MCSstats = ncread(MCSstatsfile,'base_time');
        %datetime_MCSstats = ncread(MCSstatsfile,'datetimestring');  datetime_MCSstats = permute(datetime_MCSstats,[2 3 1]);
        times_MCSstats = ncread(MCSstatsfile,'times');
        tracks_MCSstats = ncread(MCSstatsfile,'tracks');

        meanlat_MCSstats = ncread(MCSstatsfile,'meanlat');
        meanlon_MCSstats = ncread(MCSstatsfile,'meanlon');
        area_MCSstats = ncread(MCSstatsfile,'core_area');
        %majoraxis_MCSstats = ncread(MCSstatsfile,'majoraxislength');
        speed_MCSstats = ncread(MCSstatsfile,'movement_speed');
        dirmotion_MCSstats = ncread(MCSstatsfile,'movement_theta');
        % Cx_MCSstats = ncread(MCSstatsfile,'uspeed');
        % Cy_MCSstats = ncread(MCSstatsfile,'vspeed');
        duration_MCSstats = ncread(MCSstatsfile,'track_duration');
        tracknum_MCSstats = ncread(MCSstatsfile,'cloudnumber');
        status_MCSstats = ncread(MCSstatsfile,'track_status');
        pfstatus_MCSstats = ncread(MCSstatsfile,'pf_mcsstatus');
        lifecycle_MCSstatus = ncread(MCSstatsfile,'lifecycle_stage');
        pfarea_MCSstats = ncread(MCSstatsfile,'pf_area');
        pflon_MCSstats = ncread(MCSstatsfile,'pf_lon');
        pflat_MCSstats = ncread(MCSstatsfile,'pf_lat');
        pfrainrate_MCSstats = ncread(MCSstatsfile,'pf_rainrate');

        pfETH10_MCSstats = ncread(MCSstatsfile,'pf_coremaxechotop10');
        pfETH30_MCSstats = ncread(MCSstatsfile,'pf_coremaxechotop30');
        pfETH40_MCSstats = ncread(MCSstatsfile,'pf_coremaxechotop40');
        pfETH45_MCSstats = ncread(MCSstatsfile,'pf_coremaxechotop45');
        pfETH50_MCSstats = ncread(MCSstatsfile,'pf_coremaxechotop50');

        pfcca40_MCSstats = ncread(MCSstatsfile,'pf_cc40area');
        pfcca45_MCSstats = ncread(MCSstatsfile,'pf_cc45area');
        pfcca50_MCSstats = ncread(MCSstatsfile,'pf_cc50area');        

        totalrain_MCSstats = ncread(MCSstatsfile,'total_rain');
        totalheavyrain_MCSstats = ncread(MCSstatsfile,'total_heavyrain');
        convrain_MCSstats = ncread(MCSstatsfile,'conv_rain');
        stratrain_MCSstats = ncread(MCSstatsfile,'strat_rain');

        pf_convrate_MCSstats = ncread(MCSstatsfile,'pf_ccrainrate');
        pf_stratrate_MCSstats = ncread(MCSstatsfile,'pf_sfrainrate');
        pf_convarea_MCSstats = ncread(MCSstatsfile,'pf_ccarea');
        pf_stratarea_MCSstats = ncread(MCSstatsfile,'pf_sfarea');

        pf_maxrainrate_MCSstats = ncread(MCSstatsfile,'pf_maxrainrate');
        pf_accumrain_MCSstats = ncread(MCSstatsfile,'pf_accumrain');
        pf_accumrainheavy_MCSstats = ncread(MCSstatsfile,'pf_accumrainheavy');
        rainrate_heavyrain_MCSstats = ncread(MCSstatsfile,'rainrate_heavyrain');

        basetime_MCSstats_met_yymmddhhmmss = datetime(basetime_MCSstats, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') ;




        % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
        % cull MCSs outside of the lat/lon sub dom box range:
        % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

        MASK_KEEPERS_MCS = [];  MASK_TOSSERS_MCS = [];

        for n = 1  :  length(tracks_MCSstats)

            % n = 101;

            %find the track number that has a centroid outside of the subdomain during MCSI period (t = 1-3):

            clear loccheck
            loccheck = find( meanlat_MCSstats(1:3,n) < latrange(1) | meanlat_MCSstats(1:3,n) > latrange(2)  |   ...
                meanlon_MCSstats(1:3,n) < lonrange(1) | meanlon_MCSstats(1:3,n) > lonrange(2)  ) ;  % number of times in first 3 times of MCS when its outside of box (i.e., part of MCSI could be out of box)

            if(isempty(loccheck)==0) %if you found an outside subdom MCSI event

                MASK_TOSSERS_MCS = vertcat(MASK_TOSSERS_MCS,n); % list of MCS nums this year that MCSI outside of box

                basetime_MCSstats(:,n) = NaN;
                meanlat_MCSstats(:,n) = NaN;
                meanlon_MCSstats(:,n) = NaN;
                area_MCSstats(:,n) = NaN;
                speed_MCSstats(:,n) = NaN;
                dirmotion_MCSstats(:,n) = NaN;
                duration_MCSstats(n) = NaN;
                tracknum_MCSstats(:,n) = NaN;
                status_MCSstats(:,n) = NaN;
                pfstatus_MCSstats(:,:,n) = NaN;
                lifecycle_MCSstatus(:,n) = NaN;
                pfarea_MCSstats(:,:,n) = NaN;
                pflon_MCSstats(:,:,n) = NaN;
                pflat_MCSstats(:,:,n) = NaN;
                pfrainrate_MCSstats(:,:,n) = NaN;
                totalrain_MCSstats(:,n) = NaN;
                totalheavyrain_MCSstats(:,n) = NaN;
                convrain_MCSstats(:,n) = NaN;
                stratrain_MCSstats(:,n) = NaN;

                pfETH10_MCSstats(:,:,n) = NaN;
                pfETH30_MCSstats(:,:,n) = NaN;
                pfETH40_MCSstats(:,:,n) = NaN;
                pfETH45_MCSstats(:,:,n) = NaN;
                pfETH50_MCSstats(:,:,n) = NaN;

                pfcca40_MCSstats(:,:,n) = NaN;
                pfcca45_MCSstats(:,:,n) = NaN;
                pfcca50_MCSstats(:,:,n) = NaN;                

                pf_maxrainrate_MCSstats(:,:,n) = NaN;
                pf_convrate_MCSstats(:,:,n) = NaN;
                pf_stratrate_MCSstats(:,:,n) = NaN;
                pf_convarea_MCSstats(:,:,n) = NaN;
                pf_stratarea_MCSstats(:,:,n) = NaN;

                pf_accumrain_MCSstats(:,:,n) = NaN;
                pf_accumrainheavy_MCSstats(:,:,n) = NaN;
                rainrate_heavyrain_MCSstats(:,n) = NaN;

            elseif( isempty(loccheck) )

                MASK_KEEPERS_MCS = vertcat(MASK_KEEPERS_MCS,n); % list of MCS nums this year that MCSI inside of box

            end

        end






        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%% make masks to cull unwanted MCS tracks:
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %     dummy = tracknum_MCSstats; dummy(:) = nan;    %  f(time, num of tracks)
        %
        %     % mask to nan-out tracks that never have a centroid lat/lon somehwere over [most of] CONUS
        %     MASK_zone_mcs = [1:length(tracks_MCSstats)];  MASK_zone_mcs(:) = nan;
        %
        %     disp('   ')
        %     disp(' making subdomain MCS masks')
        %     tic

        %     %trim MCSs initiate (approx as t = 1-5) outside of prescribed lat/lon box
        %     for n = 1:length(tracks_MCSstats)
        %         % n = 111;
        %         clear loccheck
        %         loccheck = find( meanlat_MCSstats(1:5,n) > latrange(1) & meanlat_MCSstats(1:5,n) < latrange(2)     & ...
        %             meanlon_MCSstats(1:5,n) > lonrange(1) & meanlon_MCSstats(1:5,n) < lonrange(2)  ) ;
        %         if( isempty(loccheck) == 0 ) % if not empty (i.e., MCS is in box)
        %             MASK_zone_mcs(n) = 1 ;  % NaN if MCS tracks out of the 3D MCS track field that aren't over targeted CONUS region
        %         end
        %     end
        %
        %
        %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %     %%%%%% Now Implement masks to cull unwanted MCS tracks:
        %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %     % combine (i.e.,) multiply together all of the masks you want to implement,
        %     % and catalog the keepers and tossers
        %
        %     MASKS_ALL = MASK_zone_mcs';
        %     %MASKS_ALL = MASK_zone' .* MASK_no_merge_or_split';
        %
        %     %KEEPERS = MCS track numbers that still qualify after masking,
        %     %TOSSERS = MCS track numbers that are masked out
        %     disp('   ')
        %     disp('applying MCS object mask')
        %     tic
        %     MASK_KEEPERS_MCS = [];  MASK_TOSSERS_MCS = [];
        %     for n = 1:length(MASKS_ALL)
        %         if(MASKS_ALL(n)==1)
        %             MASK_KEEPERS_MCS = vertcat(MASK_KEEPERS_MCS,n);
        %         else
        %             MASK_TOSSERS_MCS = vertcat(MASK_TOSSERS_MCS,n);
        %         end
        %     end

        %now nan-out unwanted mcs objects in their full 2D(t) track fields:
        MASKED_MCS =  cloudtracknumber_mcs;
        [ai aj at] = size(cloudtracknumber_mcs);
        parfor i = 1:ai
            for j = 1:aj
                for t = 1:at
                    for n = 1:length(MASK_TOSSERS_MCS)
                        if( cloudtracknumber_mcs(i,j,t) == MASK_TOSSERS_MCS(n)  )
                            MASKED_MCS(i,j,t) = NaN;
                        end
                    end
                end
            end
        end
        toc   % 51-70 sec
        %MASKED_MCS = permute(MASKED_MCS,[2 1 3]);
        disp('   ')

        %MASKED_MCS = permute(MASKED_MCS,[2 1 3]);


        %     % diagnostic plots:
        %     tmp = permute(MASKED_MCS,[2 1 3]);
        %     for t = 55:-1:20
        %         figure
        %         subplot(1,2,1)
        %         contourf(lon_mcs,lat_mcs,cloudtracknumber_mcs(:,:,t)',10)
        %         hold on
        %         plot(polyshape([-120 -120 -80 -80],[30 50 50 30]),'FaceColor','none')
        %         axis([-130 -60 20 60])
        %         subplot(1,2,2)
        %         contourf(lon_mcs,lat_mcs,tmp(:,:,t)',10)
        %         hold on
        %         plot(polyshape([-120 -120 -80 -80],[30 50 50 30]),'FaceColor','none')
        %         axis([-130 -60 20 60])
        %         title(num2str(t))
        %     end














        % %% %% %% %% %
        % % calculate some derivative stat quantities:
        % %% %% %% %% %


        %synoptic feature instantaneous d(AREA)/dt:
        [saa sbb] = size(area_MCSstats);
        dAdt_MCSstats = area_MCSstats;  dAdt_MCSstats(:) = NaN;
        disp('   ')
        disp('calc dAdt for MCSs')
        tic
        for t = 2:saa-1;
            for n = 1:sbb
                dAdt_MCSstats(t,n) = ( area_MCSstats(t+1,n) - area_MCSstats(t-1,n) )/( (t+1) - (t-1) );   %km2/hr
            end
        end
        toc  % instant
        disp('   ')




        %%% commenting this out because i dont think nersc has "distace" toolbox
        % calculate motion of MCS objects:

        % First convert lat/lon to x,y relative to a centralish point of MCS.
        % This could get a bit iffy as calculated over large area, so I will center it on the mean lat/long of each track:
        X_MCSstats = single(area_MCSstats); X_MCSstats(:) = NaN;
        Y_MCSstats = single(area_MCSstats); Y_MCSstats(:) = NaN;
        disp('   ')
        disp('calc mcs x and y')
        tic
        parfor t = 1:saa-1
            for n = 1:sbb
                CENlat = mean(meanlat_MCSstats(:,n),'omitnan')     ;
                CENlon = mean(meanlon_MCSstats(:,n),'omitnan')-360 ;
                az = [];
                arclen = [];
                distkm =[];
                [arclen,az] = distance(CENlat,CENlon,meanlat_MCSstats(t,n),meanlon_MCSstats(t,n));
                distkm = deg2km(arclen);
                [y_MCSstats,x_MCSstats] = pol2cart(deg2rad(az),distkm);
                X_MCSstats(t,n) = x_MCSstats ;
                Y_MCSstats(t,n) = y_MCSstats ;
                y_MCSstats = [];
                x_MCSstats = [];
            end
        end
        toc  %~20sec
        disp('   ')



        % calculate object motions:
        MotionX_MCSstats = single(area_MCSstats); MotionX_MCSstats(:) = NaN;
        MotionY_MCSstats = single(area_MCSstats); MotionY_MCSstats(:) = NaN;
        disp('   ')
        disp('calculating MCS motion vectors')
        tic
        for t = 2:saa-1
            for n = 1:sbb
                MotionX_MCSstats(t,n) = ( X_MCSstats(t+1,n) - X_MCSstats(t-1,n) )/( (t+1) - (t-1) ) * (1000/3600);   % m/s
                MotionY_MCSstats(t,n) = ( Y_MCSstats(t+1,n) - Y_MCSstats(t-1,n) )/( (t+1) - (t-1) ) * (1000/3600);   % m/s
            end
        end   % ~ instant
        toc
        disp('   ')




        % % catalog reflectivity values associated with synoptic feature:
        % % % % DOESN"T SEEM LIKE IT'S QUITE WORKING YET (MANUAL CONTOURF PLOTS SEEM LIKE IT'S NOT QUITE PICKING OF THE IN-MASK MAX REFL)
        % maxDBZ_MCSstats = area_MCSstats; maxDBZ_MCSstats(:) = NaN;
        %
        % % NEED: cloudtracknumber_mcs,  refl_mcs;  % basetime_MPtracks = basetime_mcsstats
        % for t_mcs = 1:length(basetime_mcs)
        %
        %     % t_mcs = 50;
        %
        %     bt_mcs = basetime_mcs(t_mcs);
        %
        % %     masked_refl = MP600(:,:,t_met);
        % %     masked_VOR600(isnan( cloudtracknumber_MPtracks(:,:,t_met) ))  = NaN;
        %
        %     curr_mcss = unique(cloudtracknumber_mcs(:,:,t_mcs)); curr_mcss(isnan(curr_mcss)) = [];
        %
        %     %loop through syn_features and catalog the max
        %     for n = 1:length(curr_mcss)
        %
        %         %max refl in mask:
        %         max_maskrefl = max( refl_mcs(  find(cloudtracknumber_mcs(:,:,t_mcs) == curr_mcss(n))  ),[],'omitnan' );  % max of vorticity at all pts in a synoptic mask at current time
        %
        %         %now place this in its MCSstats array by finding the syn object basetime:
        %         maxDBZ_MCSstats(  find( basetime_MCSstats(:,curr_mcss(n)) == bt_mcs) , curr_mcss(n) ) = max_maskrefl ;
        %
        %     end
        %
        % end
        % %diagnostic plots:
        % for t = 400:2:420
        %     figure;
        %
        %     subplot(2,1,1)
        %     contourf(cloudtracknumber_mcs(:,:,t),20)
        %     title(char(basetime_mcs_yymmddhhmmss(t)))
        %
        %     subplot(2,1,2)
        %     contourf(refl_mcs(:,:,t),20)
        %     title(char(basetime_mcs_yymmddhhmmss(t)))
        %
        % end










        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% 4)  Start processing stats
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%% make masks to cull unwanted MP tracks:
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %dummy = tracknum_MPstats; dummy(:) = nan;    %  f(time, num of tracks)

        % mask to nan-out tracks that never have a centroid lat/lon somehwere over [most of] CONUS
        MASK_zone = [1:length(tracks_MPstats)];  MASK_zone(:) = nan;
        % %acceptable subdomain:
        % latrange =  [20 55];
        % lonrange = [-120 -65];

        disp('   ')
        disp(' making subdomain & merge/split MP masks')
        tic



        %     %trim MP wiht centroid outside of prescribed lat/lon box at any time
        %     for n = 1:length(tracks_MPstats)
        %         clear loccheck
        %         loccheck = find( meanlat_MPstats(:,n) > latrange(1) & meanlat_MPstats(:,n) < latrange(2)     & ...
        %             meanlon_MPstats(:,n)-360 > lonrange(1) & meanlon_MPstats(:,n)-360 < lonrange(2)  ) ;
        %         if( isempty(loccheck) == 0 )
        %             MASK_zone(n) = 1 ;  % NaN's PSI tracks out of the 3D MP600 field that aren't over CONUS
        %         end
        %     end

        %cull out MP with centroid outside of prescribed lat/lon box at all times (i.e., keep MP if it is within the box at any time)
        for n = 1:length(tracks_MPstats)
            clear loccheck
            loccheck = find( meanlat_MPstats(:,n) > latrange(1) & meanlat_MPstats(:,n) < latrange(2)     & ...
                meanlon_MPstats(:,n)-360 > lonrange(1) & meanlon_MPstats(:,n)-360 < lonrange(2)  ) ;  %times in MP life when MP is within the desired box
            if( isempty(loccheck) == 0  )
                MASK_zone(n) = 1 ;  % keep MP if in the box
            end
        end



        % mask to nan-out tracks that merge/split
        MASK_no_merge_or_split = [1:length(tracks_MPstats)];  MASK_no_merge_or_split(:) = nan;
        tic
        for n = 1:length(tracks_MPstats)
            if( isnan(start_split_MPstats(n)) & isnan(end_merge_MPstats(n)) )
                MASK_no_merge_or_split(n) = 1 ;  %
            end
        end
        MP_no_merge_or_split = unique(find(MASK_no_merge_or_split==1));
        toc  %instant




        %     %  mask to exclude MPs if they are collocated with a LS - I think we need to do this later ???
        %     MASK_no_LSynoptic_feat = [1:length(tracks_MPstats)];  MASK_no_LSynoptic_feat(:) = nan;




        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%% Now Implement masks to cull unwanted MP tracks:
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % combine (i.e.,) multiply together all of the masks you want to implement,
        % and catalog the keepers and tossers

        MASKS_ALL = MASK_zone';
        %MASKS_ALL = MASK_zone' .* MASK_no_merge_or_split';

        %KEEPERS = MP track numbers that still qualify after masking,
        %TOSSERS = MP track numbers that are masked out
        disp('   ')
        disp('applying MP object mask')
        tic
        MASK_KEEPERS_MP = [];  MASK_TOSSERS_MP = [];
        for n = 1:length(MASKS_ALL)
            if(MASKS_ALL(n)==1)
                MASK_KEEPERS_MP = vertcat(MASK_KEEPERS_MP,n);
            else
                MASK_TOSSERS_MP = vertcat(MASK_TOSSERS_MP,n);
            end
        end

        %nan-out unwanted synoptic objects:
        MASKED_MP =  cloudtracknumber_MPtracks;
        [ai aj at] = size(cloudtracknumber_MPtracks);
        parfor i = 1:ai
            for j = 1:aj
                for t = 1:at
                    for n = 1:length(MASK_TOSSERS_MP)
                        if( cloudtracknumber_MPtracks(i,j,t) == MASK_TOSSERS_MP(n)  )
                            MASKED_MP(i,j,t) = NaN;
                        end
                    end
                end
            end
        end
        toc   % 51-70 sec
        MASKED_MP = permute(MASKED_MP,[2 1 3]);
        disp('   ')

        % diagnostic plots:
        %  figure; contourf(MASKED_MP(:,:,2524),10)
        %  figure; contourf(MASKED_MP2(:,:,2524),10)










        %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %     %%%%%% make masks to cull unwanted MCS tracks:
        %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %     dummy = tracknum_MCSstats; dummy(:) = nan;    %  f(time, num of tracks)
        %
        %     % mask to nan-out tracks that never have a centroid lat/lon somehwere over [most of] CONUS
        %     MASK_zone_mcs = [1:length(tracks_MCSstats)];  MASK_zone_mcs(:) = nan;
        %
        %     disp('   ')
        %     disp(' making subdomain MCS masks')
        %     tic
        %
        %     %trim MCSs initiate (approx as t = 1-5) outside of prescribed lat/lon box
        %     for n = 1:length(tracks_MCSstats)
        %         % n = 111;
        %         clear loccheck
        %         loccheck = find( meanlat_MCSstats(1:5,n) > latrange(1) & meanlat_MCSstats(1:5,n) < latrange(2)     & ...
        %             meanlon_MCSstats(1:5,n) > lonrange(1) & meanlon_MCSstats(1:5,n) < lonrange(2)  ) ;
        %         if( isempty(loccheck) == 0 ) % if not empty (i.e., MCS is in box)
        %             MASK_zone_mcs(n) = 1 ;  % NaN if MCS tracks out of the 3D MCS track field that aren't over targeted CONUS region
        %         end
        %     end
        %
        %
        %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %     %%%%%% Now Implement masks to cull unwanted MCS tracks:
        %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %     % combine (i.e.,) multiply together all of the masks you want to implement,
        %     % and catalog the keepers and tossers
        %
        %     MASKS_ALL = MASK_zone_mcs';
        %     %MASKS_ALL = MASK_zone' .* MASK_no_merge_or_split';
        %
        %     %KEEPERS = MCS track numbers that still qualify after masking,
        %     %TOSSERS = MCS track numbers that are masked out
        %     disp('   ')
        %     disp('applying MCS object mask')
        %     tic
        %     MASK_KEEPERS_MCS = [];  MASK_TOSSERS_MCS = [];
        %     for n = 1:length(MASKS_ALL)
        %         if(MASKS_ALL(n)==1)
        %             MASK_KEEPERS_MCS = vertcat(MASK_KEEPERS_MCS,n);
        %         else
        %             MASK_TOSSERS_MCS = vertcat(MASK_TOSSERS_MCS,n);
        %         end
        %     end
        %
        %     %nan-out unwanted mcs objects in their 2D(t) track fields:
        %     MASKED_MCS =  cloudtracknumber_mcs;
        %     [ai aj at] = size(cloudtracknumber_mcs);
        %     parfor i = 1:ai
        %         for j = 1:aj
        %             for t = 1:at
        %                 for n = 1:length(MASK_TOSSERS_MCS)
        %                     if( cloudtracknumber_mcs(i,j,t) == MASK_TOSSERS_MCS(n)  )
        %                         MASKED_MCS(i,j,t) = NaN;
        %                     end
        %                 end
        %             end
        %         end
        %     end
        %     toc   % 51-70 sec
        %     MASKED_MCS = permute(MASKED_MCS,[2 1 3]);
        %     disp('   ')
        %
        % %     % diagnostic plots:
        % %     tmp = permute(MASKED_MCS,[2 1 3]);
        % %     for t = 600:-1:540
        % %         figure
        % %         subplot(1,2,1)
        % %         contourf(lon_mcs,lat_mcs,cloudtracknumber_mcs(:,:,t)',10)
        % %         hold on
        % %         plot(polyshape([-120 -120 -80 -80],[30 50 50 30]),'FaceColor','none')
        % %         axis([-130 -60 20 60])
        % %         subplot(1,2,2)
        % %         contourf(lon_mcs,lat_mcs,tmp(:,:,t)',10)
        % %         hold on
        % %         plot(polyshape([-120 -120 -80 -80],[30 50 50 30]),'FaceColor','none')
        % %         axis([-130 -60 20 60])
        % %     end









        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%% Pair-up MCSs and MP objects per met time (also record
        %%%%%%%%%%%%% some era5 vars to MCSstats arrays)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



        [lon2d_mcs lat2d_mcs] = meshgrid( lon_mcs,lat_mcs  );

        %%%% define a log of all of the MP tracks tagged to an MCS lifetime by MCS track number:
        MPtracks_perMCS = basetime_MCSstats ;  % f(MCS number, MCS lifetime in hours) - this is MCS stats frame work
        MPtracks_perMCS(:) = NaN ;
        tbad = [1:cc]; tbad(:) = NaN;


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Loop thru met times to find MASKED MP objects that are collocated with MCS objects:
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        disp('   ')
        disp('loop to pair MP and MCSs')
        tic
        for t_met = 1:sa-1% cc %cc or sa-1? I think sa-1
            % t_met is the MP time indices

            % t_met = 900;  %(for yr = 1)

            % conversion to met (i.e., PSI) time to MCS time:
            t_mcs = find( floor(basetime_MPtracks(t_met)/100) == floor(basetime_mcs/100) ) ;    %the /100 and rounding seems to be necessary to eliminate some random few dozens fo seconds added to the basetime.

            % t_LS = find( floor(basetime_MPtracks(t_met)/100) == floor(basetime_LStracks/100) ) ;


            % diagnostic:
            %  basetime_met_yymmddhhmmss(t_met)
            %  basetime_mcs_yymmddhhmmss(t_mcs)
            %  basetime_LS_yymmddhhmmss(t_LS)

            if( isempty(t_mcs) ==0  )  % if there is an MCS at this time (emergency MCS glitch catch)

                tbad(t_met) = 0 ;

                % MCS track scene at cur met time:
                %tracknumber_m = cloudtracknumber_mcs(:,:,t_mcs) ;
                tracknumber_m = MASKED_MCS(:,:,t_mcs) ;
                tracknumber_m(find( isnan(tracknumber_m == 0 ) )) = 1 ;
                tracknumber_m(find( isnan(tracknumber_m ) )) = 0 ;
                mtrack = permute(tracknumber_m,[2 1]) ;

                %interpolate current mcs mask to the met grid:
                [lonm latm] =meshgrid(lon_mcs+360,lat_mcs);
                [lone late] =meshgrid(lon_met,lat_met);
                mcsmask_on_metgrid = interp2(lonm,latm,mtrack,lone,late,'nearest') ;

                %MCS track numbers in current met scene:
                CurrMCSs = mcsmask_on_metgrid(find(mcsmask_on_metgrid > 0)) ;
                CurrMCSs = unique(CurrMCSs) ;


                if( isempty(CurrMCSs) == 0 )  %if there is an MCS in the current met time:

                    %where MP masks and MCS masks overlap spatially in curr met scene:
                    for m = 1:length(CurrMCSs)  %loop thru mcs tracks

                        % MCS and MP overlapping points on met grid:
                        [overlapi overlapj] = find( MASKED_MP(:,:,t_met) > 0  &  mcsmask_on_metgrid == CurrMCSs(m) ) ;
                        % diagnostic:
                        % figure; contourf(lon_met-360,lat_met,mcsmask_on_metgrid); hold on; plot(lon_met(overlapj)-360,lat_met(overlapi),'ko'); %axis([-100 -94 32.5 36])
                        % figure;  contourf(lon_met-360,lat_met,MASKED_MP(:,:,t_met));  %axis([-100 -94 32.5 36])

                        % fraction of the MCS (by pixel count) occupied by the MP obj (for overlap-threshold later)
                        overlapfract = length(overlapi) / length(find(mcsmask_on_metgrid == CurrMCSs(m))) ;

                        %get the MP track number overlapping with current MCS track/time:
                        curr_MP_features =  MASKED_MP(overlapi, overlapj,t_met) ;
                        curr_MP_feature =  unique(curr_MP_features) ;
                        curr_MP_feature( find(curr_MP_feature==0) ) = [] ;
                        curr_MP_feature( isnan(curr_MP_feature) ) = [] ;

                        %diagnostic plots:
                        % figure; contourf(MASKED_MP(:,:,t_met),20); hold on; contour(mcsmask_on_metgrid)
                        % figure; contourf(mcsmask_on_metgrid,20);

                        % if there's an MP(s) touching the MCS and by the fraction prescribed, log it:
                        if( isempty(curr_MP_feature)==0  & overlapfract >= objoverlapthresh )

                            %pick the MP feature with the most overlap with MCS
                            num = 0; %reset num
                            for q = 1:length(curr_MP_feature)
                                num(q) = length(find( curr_MP_feature(q) == curr_MP_features) );
                            end
                            curr_MP_feature = curr_MP_feature( find( max(num) == num ) );

                            % log the MP track touching the MCS currently
                            mtime = find(  floor(basetime_MPtracks(t_met)/100) == floor( basetime_MCSstats(:,CurrMCSs(m))/100 )  ) ; %time index in MCS's stat history correspond to curr met time
                            if(   isempty(mtime)==0   )
                                MPtracks_perMCS(mtime,CurrMCSs(m)) = curr_MP_feature(1);   %NOTE: I CAME ACROSS AN EXAMPLE WHERE
                                % AN MCS OVERLAPPED WITH THE SAME NUMBER OF POINTS FROM TWO DIFFERENT MP TRACKS. I
                                % ARBITRARILY PICK THE FIRST ONE. I DEFAULTED TO THIS BECAUSE I HAVE NO
                                % OTHER IDEAS WITHOUT AN INFRASTRUCTURE TO SAVE MULITPLE SYNOPTIC TRACKS TO AN MCS
                            end

                        else  % if there is an MCS, but no/insufficient overlap with a MP feature

                            % log the synoptic track touching the MCS currently
                            mtime = find(  floor(basetime_MPtracks(t_met)/100) == floor( basetime_MCSstats(:,CurrMCSs(m))/100 )  ) ; %time index in MCS's stat history correspond to curr met time
                            %mtime = find(  basetime_MPtracks(t_met) == basetime_MCSstats(:,CurrMCSs(m))  ) ; %time index in MCS's stat history correspond to curr met time

                            if(isempty(mtime)==0)
                                MPtracks_perMCS(mtime,CurrMCSs(m)) = -1;    %MCS time with no synoptic feature overhead

                            end


                        end % if there is/isn't overlap between mcs and MP


                    end  % loop thru current MCSs
                end  % if there is an MCS at curr met time

            else

                tbad(t_met) = 1;

            end %emergency MCS glitch catch

        end
        toc   % for O[10sec]
        disp('   ')



        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % catalog al MP track numbers with MCSs :
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        MP_with_MCSs = unique(MPtracks_perMCS) ;
        MP_with_MCSs(isnan(MP_with_MCSs)) = [] ;
        MP_with_MCSs(MP_with_MCSs==-1) = [] ;



        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % catalog all MASKED_MP track numbers without MCSs :
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        disp('   ')
        disp('catalog MP objs without MCSs')
        tic
        MP_without_MCSs = unique(MASKED_MP) ;
        MP_without_MCSs(isnan(MP_without_MCSs)) = [];
        for n = 1:length(MP_without_MCSs)
            for m = 1:length(MP_with_MCSs)
                if(MP_without_MCSs(n) == MP_with_MCSs(m))
                    MP_without_MCSs(n) = -999;
                end
            end
        end
        MP_without_MCSs( MP_without_MCSs == -999 ) = [];
        toc  %for ~ 10 sec



        % all the other MP that we dont care about:
        disp('   ')
        disp('catalog the other MP objects that we dont really care about')
        tic
        MP_other = [1:length(tracks_MPstats)];
        MCS_and_noMCS = vertcat(MP_with_MCSs,MP_without_MCSs);
        for m = 1:length(MCS_and_noMCS)
            MP_other(find(MP_other == MCS_and_noMCS(m))) = -999;
        end
        MP_other( find(MP_other == -999) ) = [];
        toc %for < 1 sec




        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %    plots of MASKed MP mask field:
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        disp('   ')
        disp('applying MPmasks masked - parfor')
        tic
        MPmasks_masked = cloudtracknumber_MPtracks;
        [ai aj at] = size(cloudtracknumber_MPtracks);
        parfor i = 1:ai
            for j = 1:aj
                for t = 1:at
                    for n = 1:length(MASK_KEEPERS_MP)
                        if( MPmasks_masked(i,j,t) == MASK_KEEPERS_MP(n)  )
                            MPmasks_masked(i,j,t) = 10000;
                        end
                    end
                end
            end
        end

        parfor i = 1:ai
            for j = 1:aj
                for t = 1:at
                    for n = 1:length(MASK_TOSSERS_MP)
                        if( MPmasks_masked(i,j,t) == MASK_TOSSERS_MP(n)  )
                            MPmasks_masked(i,j,t) = -1;
                        end
                    end
                end
            end
        end
        MPmasks_masked( isnan(MPmasks_masked)  ) = 0;
        MPmasks_masked( MPmasks_masked == 10000 ) = 1;
        toc   % 42  sec
        disp('   ')


        % % diagnostic plots:
        %  figure; contourf(MPmasks_masked(:,:,2524),10)
        %  figure; contourf(MPmasks_masked2(:,:,2524),10)


        %parfor under construction:
        disp('   ')
        disp('MP objs masked with mcs - parfor')
        tic
        MPmasks_masked_withmcs = cloudtracknumber_MPtracks;
        [ai aj at] = size(cloudtracknumber_MPtracks);
        parfor i = 1:ai
            for j = 1:aj
                for t = 1:at
                    for n = 1:length(MP_with_MCSs)
                        if( MPmasks_masked_withmcs(i,j,t) == MP_with_MCSs(n)   )
                            MPmasks_masked_withmcs(i,j,t) = 100000;
                        end
                    end
                end
            end
        end

        parfor i = 1:ai
            for j = 1:aj
                for t = 1:at
                    for n = 1:length(MP_without_MCSs)
                        if( MPmasks_masked_withmcs(i,j,t) == MP_without_MCSs(n)   )
                            MPmasks_masked_withmcs(i,j,t) = NaN;
                        end
                    end
                end
            end
        end

        parfor i = 1:ai
            for j = 1:aj
                for t = 1:at
                    for n = 1:length(MP_other)
                        if( MPmasks_masked_withmcs(i,j,t) == MP_other(n) )
                            MPmasks_masked_withmcs(i,j,t) = NaN;
                        end
                    end
                end
            end
        end
        toc   % for is 45  sec!!

        MPmasks_masked_withmcs(find(MPmasks_masked_withmcs == 100000))   = 1;
        MPmasks_masked_withmcs( isnan(MPmasks_masked_withmcs)  )         = 0;
        disp('   ')


        % % diag plots
        %  figure; contourf(MPmasks_masked_withmcs(:,:,2460),20)
        %  figure; contourf(MPmasks_masked_withmcs2(:,:,2460),20)





        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%% Now match MCS and MP objects with LS objects:
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


        %%% Do I need/want to lat/lon & merge/split filter the large-scale vorts too?
        % for now, i'm just going to bypass LS masking/filtering for the moment and just keep them all :

        MASKS_ALL_LS = [1:length(tracks_LSstats)];   MASKS_ALL_LS(:) = 1;
        %    for n = 1:length(tracks_LSstats)
        %         clear loccheck
        %         loccheck = find( meanlat_MPstats(:,n) > latrange(1) & meanlat_MPstats(:,n) < latrange(2)     & ...
        %             meanlon_MPstats(:,n)-360 > lonrange(1) & meanlon_MPstats(:,n)-360 < lonrange(2)  ) ;
        %         if( isempty(loccheck) == 0 )
        %             MASK_zone(n) = 1 ;  % NaN's PSI tracks out of the 3D MP600 field that aren't over CONUS
        %         end
        %    end
        %
        %     MASK_KEEPERS_LS = [];  MASK_TOSSERS_LS = [];
        %     for n = 1:length(MASKS_ALL_LS)
        %         if(MASKS_ALL(n)==1)
        %             MASK_KEEPERS_LS = vertcat(MASK_KEEPERS_LS,n);
        %         else
        %             MASK_TOSSERS_LS = vertcat(MASK_TOSSERS_LS,n);
        %         end
        %     end
        MASK_KEEPERS_LS = [1:length(tracks_LSstats)];
        MASK_TOSSERS_LS = []  ;

        %nan-out unwanted LS objects:  (for now, this filters nothing and just keeps all LS in "MASKED_LS")
        MASKED_LS =  cloudtracknumber_LStracks;
        [ai aj at] = size(cloudtracknumber_LStracks);
        parfor i = 1:ai
            for j = 1:aj
                for t = 1:at
                    for n = 1:length(MASK_TOSSERS_LS)
                        if( cloudtracknumber_LStracks(i,j,t) == MASK_TOSSERS_LS(n)  )
                            MASKED_LS(i,j,t) = NaN;
                        end
                    end
                end
            end
        end
        toc   % 51-70 sec
        MASKED_LS = permute(MASKED_LS,[2 1 3]);




        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%% match-up MCSs and LS objects per met time (also record
        %%%%%%%%%%%%% some era5 vars to MCSstats arrays)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



        [lon2d_mcs lat2d_mcs] = meshgrid( lon_mcs,lat_mcs  );

        %%%% define a log of all of the LS tracks tagged to an MCS lifetime by MCS track number:
        LStracks_perMCS = basetime_MCSstats ;  % f(MCS number, MCS lifetime in hours) - this is MCS stats frame work
        LStracks_perMCS(:) = NaN ;
        tbadLS = [1:cc]; tbadLS(:) = NaN;


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Loop thru met times to find MASKED LS objects that are collocated with MCS objects:
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        disp('   ')
        disp('loop to pair LSs and MCSs')
        tic
        for t_met = 1:sa-1% cc %cc or sa-1? I think sa-1
            % t_met is the LS time indices

            % conversion to met (i.e., PSI) time to MCS time:
            t_mcs = find( floor(basetime_LStracks(t_met)/100) == floor(basetime_mcs/100) ) ;    %the /100 and rounding seems to be necessary to eliminate some random few dozens fo seconds added to the basetime.

            % diagnostic:
            %  basetime_met_yymmddhhmmss(t_met)
            %  basetime_mcs_yymmddhhmmss(t_mcs)
            %  basetime_LS_yymmddhhmmss(t_LS)

            if( isempty(t_mcs) ==0  )  % if there is an MCS at this time (emergency MCS glitch catch)

                tbadLS(t_met) = 0;

                % MCS track scene at cur met time:
                tracknumber_m = MASKED_MCS(:,:,t_mcs) ;
                %tracknumber_m = cloudtracknumber_mcs(:,:,t_mcs) ;
                tracknumber_m(find( isnan(tracknumber_m == 0 ) )) = 1 ;
                tracknumber_m(find( isnan(tracknumber_m ) )) = 0 ;
                mtrack = permute(tracknumber_m,[2 1]) ;

                %interpolate current mcs mask to the met grid:
                [lonm latm] =meshgrid(lon_mcs+360,lat_mcs);
                [lone late] =meshgrid(lon_met,lat_met);
                mcsmask_on_metgrid = interp2(lonm,latm,mtrack,lone,late,'nearest') ;

                %MCS track numbers in current met scene:
                CurrMCSs = mcsmask_on_metgrid(find(mcsmask_on_metgrid > 0)) ;
                CurrMCSs = unique(CurrMCSs) ;


                if( isempty(CurrMCSs) == 0 )  %if there is an MCS in the current met time:

                    %where PSI masks and MCS masks overlap spatially in curr met scene:
                    for m = 1:length(CurrMCSs)  %loop thru mcs tracks

                        % MCS and PSI overlapping points on met grid:
                        [overlapi overlapj] = find( MASKED_LS(:,:,t_met) > 0  &  mcsmask_on_metgrid == CurrMCSs(m) ) ;
                        % plot(lon_met(overlon),lat_met(overlat),'o')  %diagnostic plot

                        % fraction of the MCS (by pixel count) occupied by the LS obj (for overlap-threshold later)
                        overlapfract = length(overlapi) / length(find(mcsmask_on_metgrid == CurrMCSs(m))) ;

                        %get the synoptoc track number overlapping with current MCS
                        %track/time:
                        curr_LS_features =  MASKED_LS(overlapi, overlapj,t_met) ;
                        curr_LS_feature =  unique(curr_LS_features) ;
                        curr_LS_feature( find(curr_LS_feature==0) ) = [] ;
                        curr_LS_feature( isnan(curr_LS_feature) ) = [] ;

                        %diagnostic plots:
                        % figure; contourf(MASKED_LS(:,:,t_met),20); hold on; contour(mcsmask_on_metgrid)
                        % figure; contourf(mcsmask_on_metgrid,20);

                        % if there's an LS(s) touching the MCS and by the fraction prescribed, log it:
                        if( isempty(curr_LS_feature)==0  & overlapfract >= objoverlapthresh )

                            %pick the LS feature with the most overlap with MCS
                            num = 0; %reset num
                            for q = 1:length(curr_LS_feature)
                                num(q) = length(find( curr_LS_feature(q) == curr_LS_features) );
                            end
                            curr_LS_feature = curr_LS_feature( find( max(num) == num ) );

                            % log the LS track touching the MCS currently
                            mtime = find(  floor(basetime_LStracks(t_met)/100) == floor( basetime_MCSstats(:,CurrMCSs(m))/100 )  ) ; %time index in MCS's stat history correspond to curr met time
                            if(isempty(mtime)==0)
                                LStracks_perMCS(mtime,CurrMCSs(m)) = curr_LS_feature(1);   %NOTE: I CAME ACROSS AN EXAMPLE WHERE
                                % AN MCS OVERLAPPED WITH THE SAME NUMBER OF POINTS FROM TWO DIFFERENT SYNOPTIC TRACKS. I
                                % ARBITRARILY PICK THE FIRST ONE. I CANT CLAIM TO BE A FAN OF THIS, BUT I HAVE NO
                                % OTHER IDEAS WITHOUT AN INFRASTRUCTURE TO SAVE MULITPLE SYNOPTIC TRACKS TO AN MCS
                            end


                        else  % if there is an MCS, but no overlap with a synoptic feature

                            % log the synoptic track touching the MCS currently
                            mtime = find(  floor(basetime_LStracks(t_met)/100) == floor( basetime_MCSstats(:,CurrMCSs(m))/100 )  ) ; %time index in MCS's stat history correspond to curr met time
                            %mtime = find(  basetime_MPtracks(t_met) == basetime_MCSstats(:,CurrMCSs(m))  ) ; %time index in MCS's stat history correspond to curr met time

                            if(isempty(mtime)==0)
                                LStracks_perMCS(mtime,CurrMCSs(m)) = -1;    %MCS time with no synoptic feature overhead

                            end


                        end % if there is/isn't overlap between mcs and synoptics


                    end  % loop thru current MCSs
                end  % if there is an MCS at curr met time

            else

                tbadLS(t_met) = 1;

            end %emergency MCS glitch catch

        end
        toc   % for ~ 60sec
        disp('   ')



        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % catalog al LS track numbers with MCSs :
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        LS_with_MCSs = unique(LStracks_perMCS) ;
        LS_with_MCSs(isnan(LS_with_MCSs)) = [] ;
        LS_with_MCSs(LS_with_MCSs==-1) = [] ;



        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % catalog all MASKED_LS track numbers without MCSs :
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        disp('   ')
        disp('catalog LS objs without MCSs')
        tic
        LS_without_MCSs = unique(MASKED_LS) ;
        LS_without_MCSs(isnan(LS_without_MCSs)) = [];
        for n = 1:length(LS_without_MCSs)
            for m = 1:length(LS_with_MCSs)
                if(LS_without_MCSs(n) == LS_with_MCSs(m))
                    LS_without_MCSs(n) = -999;
                end
            end
        end
        LS_without_MCSs( LS_without_MCSs == -999 ) = [];
        toc  %for ~ 10 sec



        % all the other LS that we dont care about:
        disp('   ')
        disp('catalog the other LS objects that we dont really care about')
        tic
        LS_other = [1:length(tracks_LSstats)];
        MCS_and_noMCS = vertcat(LS_with_MCSs,LS_without_MCSs);
        for m = 1:length(MCS_and_noMCS)
            LS_other(find(LS_other == MCS_and_noMCS(m))) = -999;
        end
        LS_other( find(LS_other == -999) ) = [];
        toc %for < 1 sec




        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %    plots of MASKed M' mask field:
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        disp('   ')
        disp('applying LS masks masked - parfor')
        tic
        LSmasks_masked = cloudtracknumber_LStracks;
        [ai aj at] = size(cloudtracknumber_LStracks);
        parfor i = 1:ai
            for j = 1:aj
                for t = 1:at
                    for n = 1:length(MASK_KEEPERS_LS)
                        if( LSmasks_masked(i,j,t) == MASK_KEEPERS_LS(n)  )
                            LSmasks_masked(i,j,t) = 10000;
                        end
                    end
                end
            end
        end

        parfor i = 1:ai
            for j = 1:aj
                for t = 1:at
                    for n = 1:length(MASK_TOSSERS_LS)
                        if( LSmasks_masked(i,j,t) == MASK_TOSSERS_LS(n)  )
                            LSmasks_masked(i,j,t) = -1;
                        end
                    end
                end
            end
        end
        LSmasks_masked( isnan(LSmasks_masked)  ) = 0;
        LSmasks_masked( LSmasks_masked == 10000 ) = 1;
        toc   % 42  sec
        disp('   ')

        % % diagnostic plots:
        %  figure; contourf(MPmasks_masked(:,:,2524),10)
        %  figure; contourf(MPmasks_masked2(:,:,2524),10)

        %parfor under construction:
        disp('   ')
        disp('LS objs masked with mcs - parfor')
        tic
        LSmasks_masked_withmcs = cloudtracknumber_LStracks;
        [ai aj at] = size(cloudtracknumber_LStracks);
        parfor i = 1:ai
            for j = 1:aj
                for t = 1:at
                    for n = 1:length(LS_with_MCSs)
                        if( LSmasks_masked_withmcs(i,j,t) == LS_with_MCSs(n)   )
                            LSmasks_masked_withmcs(i,j,t) = 100000;
                        end
                    end
                end
            end
        end

        parfor i = 1:ai
            for j = 1:aj
                for t = 1:at
                    for n = 1:length(LS_without_MCSs)
                        if( LSmasks_masked_withmcs(i,j,t) == LS_without_MCSs(n)   )
                            LSmasks_masked_withmcs(i,j,t) = NaN;
                        end
                    end
                end
            end
        end

        parfor i = 1:ai
            for j = 1:aj
                for t = 1:at
                    for n = 1:length(LS_other)
                        if( LSmasks_masked_withmcs(i,j,t) == LS_other(n) )
                            LSmasks_masked_withmcs(i,j,t) = NaN;
                        end
                    end
                end
            end
        end
        toc   % for is 45  sec!!

        LSmasks_masked_withmcs(find(LSmasks_masked_withmcs == 100000))   = 1;
        LSmasks_masked_withmcs( isnan(LSmasks_masked_withmcs)  )         = 0;
        disp('   ')


        % % diag plots
        %  figure; contourf(MPmasks_masked_withmcs(:,:,2460),20)
        %  figure; contourf(MPmasks_masked_withmcs2(:,:,2460),20)





        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%% match-up MPs and LS objects per met time (in MP space)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


        %%% [lon2d_mcs lat2d_mcs] = meshgrid( lon_mcs,lat_mcs  );

        % define a log of all of the LS tracks tagged to an MP lifetime by MP track number:
        LStracks_perMP = basetime_MPstats ;  % f(MP number, MP lifetime in hours) - this is MP stats frame work
        LStracks_perMP(:) = NaN ;
        tbadLSmp = [1:cc]; tbadLSmp(:) = NaN;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Loop thru met times to find MASKED MP objects that are collocated with LS objects:
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        disp('   ')
        disp('loop to match LSs to MPs')
        tic

        for t_ls = 1:sa-1 % cc %cc or sa-1? I think sa-1

            % conversion to LS time to MP time: (these time indices should be 1:1 based on doing the tracking over EXACTLY the same periods)
            t_mp = find( floor(basetime_LStracks(t_ls)/100) == floor(basetime_MPtracks/100) ) ;    %the /100 and rounding seems to be necessary to eliminate some random few dozens fo seconds added to the basetime.

            if( isempty(t_mp) ==0  )  % if there is an MCS at this time (emergency MCS glitch catch)

                tbadLSmp(t_ls) = 0;

                % MP track scene at cur LS time:
                tracknumber_m = cloudtracknumber_MPtracks(:,:,t_mp) ;
                tracknumber_m(find( isnan(tracknumber_m == 0 ) )) = 1 ;
                tracknumber_m(find( isnan(tracknumber_m ) )) = 0 ;
                %mtrack = permute(tracknumber_m,[2 1]) ;
                MPs_on_LSgrid = permute(tracknumber_m,[2 1]) ;

                %             %interpolate current MP mask to the met grid:  (shouldn't need to do this as long as LS and MP domains are the same at time of tracking)
                %             [lonm latm] =meshgrid(lon_mcs+360,lat_mcs);
                %             [lone late] =meshgrid(lon_met,lat_met);
                %             mcsmask_on_metgrid = interp2(lonm,latm,mtrack,lone,late,'nearest') ;
                %%%mcsmask_on_metgrid = mtrack;

                % list of MP track numbers in current LS scene:
                CurrMPs = MPs_on_LSgrid( find(MPs_on_LSgrid > 0) ) ;
                CurrMPs = unique(CurrMPs) ;

                if( isempty(CurrMPs) == 0 )  %if there is an MP in the current LS time:

                    %where LS masks and MP masks overlap spatially in curr met scene:
                    for m = 1:length(CurrMPs)  %loop thru current MP tracks

                        % MP and LS overlapping points on LS grid:
                        [overlapi overlapj] = find( MASKED_LS(:,:,t_ls) > 0  &  MPs_on_LSgrid == CurrMPs(m) ) ;
                        % plot(lon_met(overlon),lat_met(overlat),'o')  %diagnostic plot

                        % fraction of the MP (by pixel count) occupied by the LS obj (for overlap-threshold later)
                        overlapfract = length(overlapi) / length(find(MPs_on_LSgrid == CurrMPs(m))) ;

                        %get the LS track number overlapping with current MP track/time:
                        curr_LS_features =  MASKED_LS(overlapi, overlapj,t_ls) ;
                        curr_LS_feature =  unique(curr_LS_features) ;
                        curr_LS_feature( find(curr_LS_feature==0) ) = [] ;
                        curr_LS_feature( isnan(curr_LS_feature) ) = [] ;

                        %diagnostic plots:
                        % figure; contourf(MASKED_LS(:,:,t_met),20); hold on; contour(mcsmask_on_metgrid)
                        % figure; contourf(mcsmask_on_metgrid,20);

                        % if there's an LS(s) touching the MP and by the fraction prescribed, log it:
                        if( isempty(curr_LS_feature)==0  &  overlapfract >= objoverlapthresh )
                            % pick the synoptic feature with the most overlap with MCS
                            num = 0; %reset num
                            for q = 1:length(curr_LS_feature)
                                num(q) = length(find( curr_LS_feature(q) == curr_LS_features) );
                            end
                            curr_LS_feature = curr_LS_feature( find( max(num) == num ) );

                            % log the LS track touching the MP currently
                            mtime = find(  floor(basetime_LStracks(t_ls)/100) == floor( basetime_MPstats(:,CurrMPs(m))/100 )  ) ; %time index in MCS's stat history correspond to curr met time
                            if(isempty(mtime)==0)
                                LStracks_perMP(mtime,CurrMPs(m)) = curr_LS_feature(1);   %NOTE: I CAME ACROSS AN EXAMPLE WHERE
                                % AN MP OVERLAPPED WITH THE SAME NUMBER OF POINTS FROM TWO DIFFERENT LS TRACKS. I
                                % ARBITRARILY PICK THE FIRST ONE. I CANT CLAIM TO BE A FAN OF THIS, BUT I HAVE NO
                                % OTHER IDEAS WITHOUT AN INFRASTRUCTURE TO SAVE MULITPLE LS TRACKS TO AN MP
                            end

                        else  % if there is an MP, but no overlap with a LS feature

                            % log the LS track touching the MP currently
                            mtime = find(  floor(basetime_LStracks(t_ls)/100) == floor( basetime_MPstats(:,CurrMPs(m))/100 )  ) ; %time index in MP's stat history correspond to curr met time
                            if(isempty(mtime)==0)
                                LStracks_perMP(mtime,CurrMPs(m)) = -1;    %MP time with no LS feature overhead
                            end

                        end % if there is/isn't overlap between MP and LS

                    end  % loop thru current MPs
                end  % if there is an MP at curr LS time

            else

                tbadLSmp(t_ls) = 1;

            end %emergency MP glitch catch
        end
        toc   % ~10-20 sec
        disp('   ')

        %  figure; contourf(LStracks_perMP,[0:1:60],'LineColor','none')


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % catalog all LS track numbers with MPs :
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        LSs_with_MP = unique(LStracks_perMP) ;
        LSs_with_MP(isnan(LSs_with_MP)) = [] ;
        LSs_with_MP(LSs_with_MP==-1) = [] ;


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % catalog all MASKED_LS track numbers without MCSs :
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        disp('   ')
        disp('catalog LS objs without MCSs')
        tic
        LSs_without_MP = unique(MASKED_LS) ;
        LSs_without_MP(isnan(LSs_without_MP)) = [];
        for n = 1:length(LSs_without_MP)
            for m = 1:length(LSs_with_MP)
                if(LSs_without_MP(n) == LSs_with_MP(m))
                    LSs_without_MP(n) = -999;
                end
            end
        end
        LSs_without_MP( LSs_without_MP == -999 ) = [];
        toc  %for ~ 10 sec


        % all the other LS that we dont care about:
        disp('   ')
        disp('catalog the other LS objects that we dont really care about')
        tic
        LS_other = [1:length(tracks_LSstats)];
        MPs_and_noMPs = vertcat(LSs_with_MP,LSs_without_MP);
        for m = 1:length(MPs_and_noMPs)
            LS_other(find(LS_other == MPs_and_noMPs(m))) = -999;
        end
        LS_other( find(LS_other == -999) ) = [];
        toc %for < 1 sec


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%   plots of MASKed LS mask field: - I dont think you need this if you are not MASK'ing out LSs above
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %     disp('   ')
        %     disp('applying LS masks masked - parfor')
        %     tic
        %     LSmasks_masked = cloudtracknumber_LStracks;
        %     [ai aj at] = size(cloudtracknumber_LStracks);
        %     parfor i = 1:ai
        %         for j = 1:aj
        %             for t = 1:at
        %                 for n = 1:length(MASK_KEEPERS_LS)
        %                     if( LSmasks_masked(i,j,t) == MASK_KEEPERS_LS(n)  )
        %                         LSmasks_masked(i,j,t) = 10000;
        %                     end
        %                 end
        %             end
        %         end
        %     end
        %
        %     parfor i = 1:ai
        %         for j = 1:aj
        %             for t = 1:at
        %                 for n = 1:length(MASK_TOSSERS_LS)
        %                     if( LSmasks_masked(i,j,t) == MASK_TOSSERS_LS(n)  )
        %                         LSmasks_masked(i,j,t) = -1;
        %                     end
        %                 end
        %             end
        %         end
        %     end
        %     LSmasks_masked( isnan(LSmasks_masked)  ) = 0;
        %     LSmasks_masked( LSmasks_masked == 10000 ) = 1;
        %     toc   % 42  sec
        %     disp('   ')
        %
        %
        %     % % diagnostic plots:
        %     %  figure; contourf(MPmasks_masked(:,:,2524),10)
        %     %  figure; contourf(MPmasks_masked2(:,:,2524),10)
        %
        %
        %     %parfor under construction:
        %     disp('   ')
        %     disp('LS objs masked with mcs - parfor')
        %     tic
        %     LSmasks_masked_withmcs = cloudtracknumber_LStracks;
        %     [ai aj at] = size(cloudtracknumber_LStracks);
        %     parfor i = 1:ai
        %         for j = 1:aj
        %             for t = 1:at
        %                 for n = 1:length(LS_with_MCSs)
        %                     if( LSmasks_masked_withmcs(i,j,t) == LS_with_MCSs(n)   )
        %                         LSmasks_masked_withmcs(i,j,t) = 100000;
        %                     end
        %                 end
        %             end
        %         end
        %     end
        %
        %     parfor i = 1:ai
        %         for j = 1:aj
        %             for t = 1:at
        %                 for n = 1:length(LS_without_MCSs)
        %                     if( LSmasks_masked_withmcs(i,j,t) == LS_without_MCSs(n)   )
        %                         LSmasks_masked_withmcs(i,j,t) = NaN;
        %                     end
        %                 end
        %             end
        %         end
        %     end
        %
        %     parfor i = 1:ai
        %         for j = 1:aj
        %             for t = 1:at
        %                 for n = 1:length(LS_other)
        %                     if( LSmasks_masked_withmcs(i,j,t) == LS_other(n) )
        %                         LSmasks_masked_withmcs(i,j,t) = NaN;
        %                     end
        %                 end
        %             end
        %         end
        %     end
        %     toc   % for is 45  sec!!
        %
        %     LSmasks_masked_withmcs(find(LSmasks_masked_withmcs == 100000))   = 1;
        %     LSmasks_masked_withmcs( isnan(LSmasks_masked_withmcs)  )         = 0;
        %     disp('   ')
        %
        %
        %     % % diag plots
        %     %  figure; contourf(MPmasks_masked_withmcs(:,:,2460),20)
        %     %  figure; contourf(MPmasks_masked_withmcs2(:,:,2460),20)






        %
        % for t = 210:3:320
        %     ff = figure;
        %     contourf(lon_met,lat_met,cloudtracknumber_LStracks(:,:,t)',[0:1:10]); caxis([3 8])
        %     fileoutp2 = horzcat(outdir,'/png/LSmask_test_',ttpad, '_', char(basetime_met_yymmddhhmmss(t)));   %now done above
        %     PNGout2 = horzcat(fileoutp2,'.png');  %now done above, I think?
        %     saveas(ff,PNGout2)
        % end
        %









































        %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %     %%%%   catalog W and PW for each MP object  - serial version
        %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %     % loop through syn objects, define a radius within X degrees of the mean lat/lon of each syn obj, take max w (min omega) and mean PW within the radius, catalog it in SFPstats format:
        %
        % %     % stuff needed:
        % %
        % %     %track space
        % %     basetime_MPtracks
        % %     W600_bpf
        % %     PW
        % %     lon_met
        % %     lat_met
        % %
        % %     %stats space
        % %     basetime_MPstats
        % %     meanlat_MPstats
        % %     meanlon_MPstats
        %
        %
        %     [meshlat meshlon] = meshgrid(lat_met,lon_met);
        %     %dummy = zeros(length(lon_met),length(lat_met) );
        %
        %     maxW600bpf_MPstats_ser = zeros(length(times_MPstats),length(tracks_MPstats)); maxW600bpf_MPstats_ser(:) = NaN;
        %     meanPW_MPstats_ser = zeros(length(times_MPstats),length(tracks_MPstats));   meanPW_MPstats_ser(:) = NaN;
        %
        %     disp('   ')
        %     disp(' cataloging era5 vars for MP objects  ')
        %     disp('   ')
        %     tic
        %     for t = 1:length(times_MPstats)
        %         for s = 1:length(tracks_MPstats)
        %
        %             if(  isnan(meanlat_MPstats(t,s))==0 & isnan(meanlon_MPstats(t,s))==0  & isnan(basetime_MPstats(t,s))==0 )
        %
        %                 sublat = [];
        %                 sublon = [];
        %                 mult = [];
        %                 MP_centi = [];
        %                 MP_centj = [];
        %                 t_met = [];
        %
        %                 sublat = abs(meshlat-meanlat_MPstats(t,s))  ;
        %                 sublon = abs(meshlon-meanlon_MPstats(t,s))  ;
        %                 mult = sublat + sublon ;
        %
        %                 %  figure; contourf(mult,200); caxis([-1 40])
        %
        %                 [MP_centi, MP_centj] = find( mult == min(mult(:)) )    ;  %index location of the current syn obj on the track/era5 grid   FOR REFERENCE: i => lon; j => lat
        %                 %somtimes there are a few; kludge fix:
        %                 MP_centi = MP_centi(1);
        %                 MP_centj = MP_centj(1);
        %
        %                 %time index of syn object in met space:
        %                 t_met = find(  basetime_MPtracks == basetime_MPstats(t,s) )  ;
        %
        %                 % % diagnostic plots:
        %                 %             figure;
        %                 %             contourf(tracknumber_MPtracks(:,:,t_met),20);
        %                 %             hold on
        %                 %             plot(MP_centj, MP_centi,'ok','MarkerSize',15)
        %
        %
        %                 rangeINT = 2; % multiplier of the circular equiv radius (INT*degrees) from syn obj center you are averaging/operating upon
        %                 %dist = zeros(length(lon_met),length(lat_met) );
        %
        %
        %                 % distance in the met framework from cyrrent MP obj center
        %                 [ai aj] = size(tracknumber_MPtracks(:,:,1)) ;
        %
        %                 dist = [];
        %                 for i = 1:ai
        %                     for j = 1:aj
        %
        %                         mpR = [];
        %
        %                         %equivalent radius of syn object
        %                         mpR = ( area_MPstats(t,s)/3.14159 ).^0.5 / 100 ;  %this 100 dividend is a kludge conversion of ~100km/1deg... which is obviously imperfect but maybe good enough over CONUS for what we are doing with it?
        %
        %                         dist(i,j) = 0.25*( (i-MP_centi).*(i-MP_centi) + (j-MP_centj).*(j-MP_centj) ).^0.5 ;   %% UNITS = DEGREES
        %
        %
        %                         if( dist(i,j) > rangeINT .* mpR )
        %                             dist(i,j) = NaN;  %nan it out beyond your prescribed distance from syn obj
        %                         else
        %                             dist(i,j) = 1;   % one it if within prescribed range
        %                         end
        %                     end
        %                 end
        %
        %
        %                 %             % diagnostic plots
        %                 %             figure;
        %                 %             hold on;
        %                 %             contourf(lon_met-360,lat_met,tracknumber_MPtracks(:,:,t_met)',30)
        %                 %             contour(lon_met-360,lat_met,dist',[1:1:30],'k');
        %                 %             plot(lon_met(MP_centi)-360,lat_met(MP_centj),'rd');
        %                 %             load coastlines
        %                 %             plot(coastlon,coastlat,'Color',[0.8 0 0.5],'LineWidth',0.75);  % plot(fliplon,coastlat,'.k')
        %                 %             axis equal
        %                 %             axis([-170 -50 20 60])
        %                 %
        %                 %             figure; contourf(tracknumber_MPtracks(:,:,t_met)',30); hold on; plot(MP_centi,MP_centj,'rd');
        %
        %
        %                 %%%% now catalog the era5 metrics of interest:
        %
        %                 maxW600bpf_MPstats_ser(t,s) =   min( min( ( W600_bpf(:,:,t_met) .*  dist),[],'omitnan' ),[],'omitnan' )   ;
        %                 meanPW_MPstats_ser(t,s)     =   mean( mean( PW(:,:,t_met) .*  dist, 'omitnan' ),'omitnan' )   ;
        %
        %
        % %                 maxW600bpf_MPstats(t,s) =   min( min( ( W600_bpf(:,:,t_met) .*  dist),[],'omitnan' ),[],'omitnan' )   ;
        % %                 meanPW_MPstats(t,s)     =   mean( mean( PW(:,:,t_met) .*  dist, 'omitnan' ),'omitnan' )   ;
        %             end
        %         end
        %     end
        %     toc   % 230 sec
        %     disp('   ')











        %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %     %%%%   catalog W and PW for each syn object  - parallel version
        %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        [meshlat meshlon] = meshgrid(lat_met,lon_met);
        %dummy = zeros(length(lon_met),length(lat_met) );

        %initialize variables you want in synoptic object stats space:
        maxW600bpf_MPstats = zeros(length(tracks_MPstats),length(times_MPstats) );    maxW600bpf_MPstats(:) = NaN;
        maxW600_MPstats = zeros(length(tracks_MPstats),length(times_MPstats) );    maxW600_MPstats(:) = NaN;

        %     meanPW_MPstats     = zeros(length(tracks_MPstats),length(times_MPstats) );    meanPW_MPstats(:) = NaN;
        %     maxMUCAPE_MPstats     = zeros(length(tracks_MPstats),length(times_MPstats) );      maxMUCAPE_MPstats(:) = NaN;
        %     maxVIWVConv_MPstats     = zeros(length(tracks_MPstats),length(times_MPstats) );    maxVIWVConv_MPstats(:) = NaN;


        disp('   ')
        disp(' cataloging era5 vars for MP object ')
        disp('   ')

        tic
        parfor s = 1:length(tracks_MPstats)

            maxW600_S = zeros(length(times_MPstats));      maxW600_S = maxW600_S(:,1);         maxW600_S(:) = NaN;
            maxW600bpf_S = zeros(length(times_MPstats));   maxW600bpf_S = maxW600bpf_S(:,1);   maxW600bpf_S(:) = NaN;
            %         meanPW_S = zeros(length(times_MPstats));       meanPW_S = meanPW_S(:,1);           meanPW_S(:) = NaN;
            %         maxMUCAPE_S = zeros(length(times_MPstats));    maxMUCAPE_S   = maxMUCAPE_S(:,1);     maxMUCAPE_S(:) = NaN;
            %         maxVIWVConv_S = zeros(length(times_MPstats));  maxVIWVConv_S = maxVIWVConv_S(:,1);   maxVIWVConv_S(:) = NaN;

            for t = 1:length(times_MPstats)

                if(  isnan(meanlat_MPstats(t,s))==0 & isnan(meanlon_MPstats(t,s))==0  & isnan(basetime_MPstats(t,s))==0 )

                    sublat = [];
                    sublon = [];
                    mult = [];
                    MP_centi = [];
                    MP_centj = [];
                    t_met = [];

                    sublat = abs(meshlat-meanlat_MPstats(t,s))  ;
                    sublon = abs(meshlon-meanlon_MPstats(t,s))  ;
                    mult = sublat + sublon ;

                    %  figure; contourf(mult,200); caxis([-1 40])

                    [MP_centi, MP_centj] = find( mult == min(mult(:)) )    ;  %index location of the current syn obj on the track/era5 grid   FOR REFERENCE: i => lon; j => lat
                    %somtimes there are a few; kludge fix:
                    MP_centi = MP_centi(1);
                    MP_centj = MP_centj(1);

                    %time index of syn object in met space:
                    t_met = find(  basetime_MPtracks == basetime_MPstats(t,s) )  ;

                    % % diagnostic plots:
                    %             figure;
                    %             contourf(tracknumber_MPtracks(:,:,t_met),20);
                    %             hold on
                    %             plot(MP_centj, MP_centi,'ok','MarkerSize',15)


                    rangeINT = 2; % multiplier of the circular equiv radius (INT*degrees) from syn obj center you are averaging/operating upon
                    %dist = zeros(length(lon_met),length(lat_met) );


                    % distance in the met framework from cyrrent syn obj center
                    [ai aj] = size(tracknumber_MPtracks(:,:,1)) ;

                    dist = [];
                    for i = 1:ai
                        for j = 1:aj

                            mpR = [];

                            %equivalent radius of syn object
                            mpR = ( area_MPstats(t,s)/3.14159 ).^0.5 / 100 ;  %this 100 dividend is a kludge conversion of ~100km/1deg... which is obviously imperfect but maybe good enough over CONUS for what we are doing with it?

                            dist(i,j) = 0.25*( (i-MP_centi).*(i-MP_centi) + (j-MP_centj).*(j-MP_centj) ).^0.5 ;   %% UNITS = DEGREES


                            if( dist(i,j) > rangeINT .* mpR )
                                dist(i,j) = NaN;  %nan it out beyond your prescribed distance from syn obj
                            else
                                dist(i,j) = 1;   % one it if within prescribed range
                            end
                        end
                    end


                    %%%% now catalog the era5 metrics of interest for all times in each syn object
                    maxW600_S(t) =   min( min( ( W600(:,:,t_met) .*  dist),[],'omitnan' ),[],'omitnan' )   ;   %"max w" = min omega
                    maxW600bpf_S(t) =   min( min( ( W600_bpf(:,:,t_met) .*  dist),[],'omitnan' ),[],'omitnan' )   ;
                    %                 meanPW_S(t)     =   mean( mean( PW(:,:,t_met) .*  dist, 'omitnan' ),'omitnan' )   ;
                    %                 maxMUCAPE_S(t) =   max( max( ( e5CAPE(:,:,t_met) .*  dist),[],'omitnan' ),[],'omitnan' )   ;
                    %                 maxVIWVConv_S(t) =   min( min( ( e5WVD(:,:,t_met) .*  dist),[],'omitnan' ),[],'omitnan' )   ;

                end  %if
            end    %time

            %concatinate each object into stats format variable
            maxW600bpf_MPstats(s,:) =   maxW600bpf_S   ;
            maxW600_MPstats(s,:)    =   maxW600_S   ;
            %         meanPW_MPstats(s,:)     =  meanPW_S ;
            %         maxMUCAPE_MPstats(s,:)  =  maxMUCAPE_S ;
            %         maxVIWVConv_MPstats(s,:)  =  maxVIWVConv_S ;

        end
        toc   %~ 100 sec
        disp('   ')

        %flip the dimensions to be consistent with other variables
        maxW600bpf_MPstats = maxW600bpf_MPstats';
        maxW600_MPstats = maxW600_MPstats';
        %     meanPW_MPstats = meanPW_MPstats';
        %     maxMUCAPE_MPstats = maxMUCAPE_MPstats';
        %     maxVIWVConv_MPstats  = maxVIWVConv_MPstats';






        %%%%%%%% MCS centric ERA5 vars here:


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%% record
        %%%%%%%%%%%%% some era5 vars to MCSstats arrays)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


        [lon2d_met lat2d_met] = meshgrid( lon_met,lat_met  );     lon2d_met = lon2d_met - 360;
        [lon2d_mcs lat2d_mcs] = meshgrid( lon_mcs,lat_mcs  );


        %initialize variables you want in synoptic object stats space:
        maxW600bpf_MCSstats = zeros(length(tracks_MCSstats),length(times_MCSstats) );         maxW600bpf_MCSstats(:) = NaN;
        maxW600_MCSstats    = zeros(length(tracks_MCSstats),length(times_MCSstats) );         maxW600_MCSstats(:) = NaN;
        %     meanPW_MCSstats     = zeros(length(tracks_MCSstats),length(times_MCSstats) );         meanPW_MCSstats(:) = NaN;
        %     maxMUCAPE_MCSstats    = zeros(length(tracks_MCSstats),length(times_MCSstats) );       maxMUCAPE_MCSstats(:) = NaN;
        %     maxVIWVConv_MCSstats     = zeros(length(tracks_MCSstats),length(times_MCSstats) );    maxVIWVConv_MCSstats(:) = NaN;

        rangeINT = 2; % multiplier of the circular equiv radius (INT*degrees) from syn obj center you are averaging/operating upon


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Loop thru MCS times
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        disp('   ')
        disp('loop to log ERA5 vars to MCSs')

        tic

        for t = 1:length(times_MCSstats)
            for m = 1:length(tracks_MCSstats)

                % m = 250;  t = 3;

                % time index of current MCS(t,m) on ERA5 time grid.
                t_met = find( floor(basetime_MCSstats(t,m)/100) == floor(basetime_MPtracks/100) ) ;    %the /100 and rounding seems to be necessary to eliminate some random few dozens fo seconds added to the basetime.

                if( isempty(t_met) == 0  )  % emergency MCS glitch catch

                    if( isnan(meanlat_MCSstats(t,m))==0 )

                        sublat = [];
                        sublon = [];
                        mult = [];
                        mcs_centi = [];
                        mcs_centj = [];
                        %t_mcs = [];

                        %find index location of the current mcs obj on the track/era5 grid   FOR REFERENCE: i => lon; j => lat;
                        % note: meshlat/lon = era5 met grid
                        sublat = abs(lat2d_met-meanlat_MCSstats(t,m))  ;
                        sublon = abs(lon2d_met-meanlon_MCSstats(t,m))  ;
                        mult = sublat + sublon ;
                        % figure; contourf(lon2d_met,lat2d_met,mult,20)
                        [MCS_centi, MCS_centj] = find( mult == min(mult(:)) )    ;
                        %somtimes there are a few; kludge fix for the final MCS location on era5 grid:
                        MCS_centi = MCS_centi(1);
                        MCS_centj = MCS_centj(1);

                        % circ-equivalent radius of current mcs object in degrees:
                        mcsR = [];
                        mcsR = ( area_MCSstats(t,m)/3.14159 ).^0.5 / 100 ;  %this 100 dividend is a kludge conversion of ~100km/1deg... which is obviously imperfect but maybe good enough over CONUS for what we are doing with it?

                        % calculate distance field in the met framework from cyrrent mcs obj center
                        [ai aj] = size(W600(:,:,1)) ;
                        dist = W600(:,:,1); dist(:) = NaN;

                        for i = 1:ai   %loop over era5 grid
                            for j = 1:aj

                                %calculate the distance field from MCS on era5 grid
                                dist(i,j) = 0.25*( (j-MCS_centi).*(j-MCS_centi) + (i-MCS_centj).*(i-MCS_centj) ).^0.5 ;   % % UNITS = DEGREES

                                if( dist(i,j) > rangeINT .* mcsR )
                                    dist(i,j) = NaN;  %nan it out beyond your prescribed distance from syn obj
                                else
                                    dist(i,j) = 1;   % one it if within prescribed range
                                end

                            end
                        end

                        % log the era5 metric within the range from MCS:
                        maxW600bpf_MCSstats(m,t) =    min( min(    dist .*  W600_bpf(:,:,t_met),[], 'omitnan') )  ;
                        maxW600_MCSstats(m,t)    =    min( min(    dist .*  W600(:,:,t_met), [], 'omitnan'   ) ) ;
                        %                     meanPW_MCSstats(m,t)     =    mean( mean(   dist .*  PW(:,:,t_met), 'omitnan'  ),'omitnan' ) ;
                        %
                        %                     maxMUCAPE_MCSstats(m,t)       =    max( max(   dist .*  e5CAPE(:,:,t_met), [], 'omitnan'  ),[],'omitnan' ) ;
                        %                     maxVIWVConv_MCSstats(m,t)     =    min( min(   dist .*  e5WVD(:,:,t_met), [], 'omitnan'  ),[],'omitnan' ) ;

                        % % diagnostic fig:
                        % figure; contourf(lon2d_met, lat2d_met, dist',20);
                    end

                end
            end
        end

        toc   %~ 10 sec
        %correct dimension arrangement:
        maxW600bpf_MCSstats = maxW600bpf_MCSstats';
        maxW600_MCSstats = maxW600_MCSstats';
        %     meanPW_MCSstats = meanPW_MCSstats';
        %     maxMUCAPE_MCSstats = maxMUCAPE_MCSstats';
        %     maxVIWVConv_MCSstats = maxVIWVConv_MCSstats';



        % %   diagnostic plots:
        %     figure; contourf( ( PW(:,:,t_met) .*  dist ) ,30); hold on; plot(MP_centj,MP_centi,'rd'); caxis([0 50])
        %     figure; contourf( ( PW(:,:,t_met) ) ,  30); hold on; plot(MP_centj,MP_centi,'rd'); caxis([0 50])

        %     figure; contourf( ( W600_bpf(:,:,t_met) .*  dist ) , 30); hold on; plot(MP_centj,MP_centi,'rd'); caxis([-.5 .2]); colorbar
        %     figure; contourf( ( W600_bpf(:,:,t_met) ) , 50 ); hold on; plot(MP_centj,MP_centi,'rd'); caxis([-.5 .2]); colorbar
        %
        %     figure; contourf( ( W600_bpf(:,:,t_met) .*  dist ) , 30);
        %     figure; contourf( (  dist ) , 30);








        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % at this point, all LSstats, MPstats, MCSstats vars are generated. Now you can filter them now based on MASK_KEEPERS/TOSSERS_MP/MCS
        % to get rid of MPs culled by MASKED_MP
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % filter (i.e., mask out) the MP vars using MASK_TOSSERS_MP
        duration_MPstats(MASK_TOSSERS_MP) = NaN;
        area_MPstats(:,MASK_TOSSERS_MP) = NaN;
        basetime_MPstats(:,MASK_TOSSERS_MP) = NaN;
        meanlat_MPstats(:,MASK_TOSSERS_MP) = NaN;
        meanlon_MPstats(:,MASK_TOSSERS_MP) = NaN;
        status_MPstats(:,MASK_TOSSERS_MP) = NaN;
        basetime_MPstats_met_yymmddhhmmss(:,MASK_TOSSERS_MP) = NaT;
        dAdt_MPstats(:,MASK_TOSSERS_MP) = NaN;
        LStracks_perMP(:,MASK_TOSSERS_MP) = NaN;
        maxVOR600_MPstats(:,MASK_TOSSERS_MP) = NaN;
        maxW600bpf_MPstats(:,MASK_TOSSERS_MP) = NaN;
        maxW600_MPstats(:,MASK_TOSSERS_MP) = NaN;
        % meanPW_MPstats(:,MASK_TOSSERS_MP) = NaN;
        % maxMUCAPE_MPstats(:,MASK_TOSSERS_MP) = NaN;
        % maxVIWVConv_MPstats(:,MASK_TOSSERS_MP) = NaN;

        LStracks_perMCS(:,MASK_TOSSERS_MCS) = NaN;

        meanMUCAPE_MPstats(:,MASK_TOSSERS_MP) = NaN;
        maxMUCAPE_MPstats(:,MASK_TOSSERS_MP) = NaN;
        meanMUCIN_MPstats(:,MASK_TOSSERS_MP) = NaN;
        minMUCIN_MPstats(:,MASK_TOSSERS_MP) = NaN;
        meanMULFC_MPstats(:,MASK_TOSSERS_MP) = NaN;
        meanMUEL_MPstats(:,MASK_TOSSERS_MP) = NaN;
        meanPW_MPstats(:,MASK_TOSSERS_MP) = NaN;
        maxPW_MPstats(:,MASK_TOSSERS_MP) = NaN;
        minPW_MPstats(:,MASK_TOSSERS_MP) = NaN;
        meanshearmag0to2_MPstats(:,MASK_TOSSERS_MP) = NaN;
        maxshearmag0to2_MPstats(:,MASK_TOSSERS_MP) = NaN;
        meanshearmag0to6_MPstats(:,MASK_TOSSERS_MP) = NaN;
        maxshearmag0to6_MPstats(:,MASK_TOSSERS_MP) = NaN;
        meanshearmag2to9_MPstats(:,MASK_TOSSERS_MP) = NaN;
        maxshearmag2to9_MPstats(:,MASK_TOSSERS_MP) = NaN;
        meanOMEGA600_MPstats(:,MASK_TOSSERS_MP) = NaN;
        minOMEGA600_MPstats(:,MASK_TOSSERS_MP) = NaN;
        minOMEGAsub600_MPstats(:,MASK_TOSSERS_MP) = NaN;
        meanVIWVD_MPstats(:,MASK_TOSSERS_MP) = NaN;
        minVIWVD_MPstats(:,MASK_TOSSERS_MP) = NaN;
        maxVIWVD_MPstats(:,MASK_TOSSERS_MP) = NaN;
        meanDIV750_MPstats(:,MASK_TOSSERS_MP) = NaN;
        minDIV750_MPstats(:,MASK_TOSSERS_MP) = NaN;
        minDIVsub600_MPstats(:,MASK_TOSSERS_MP) = NaN;
        meanWNDSPD600(:,MASK_TOSSERS_MP) = NaN;
        meanWNDDIR600(:,MASK_TOSSERS_MP) = NaN;














        %  %  commenting because of annoying sub-function issues on nersc. can figure this out later if you want plots
        %%%%%%%%%%%%%%%%%%%%%%%
        %%% start plotting
        % start plotting
        % start plotting
        % start plotting
        % start plotting
        % start plotting
        %%%%%%%%%%%%%%%%%%%%%%%

        % load('/Volumes/LaCie/WACCEM/datafiles/Bandpass/matlab/2004_vorstats_masks_zone_v7_MatchupEnvs_objoverlap0.01percent.mat')

        dualpol_colmap

        if (plotme == 1)


            %var name bypasses to adapt to legacy code below:
            lon_met = lon_MPtracks;
            lat_met = lat_MPtracks;
            MPp600_all = MP600;
            MPp600_mask = tracknumber_MPtracks;

            LSp600_all = LS600;
            LSp600_mask = tracknumber_LStracks;

            % wrap map longitudes over -180 deg to center on pacific:
            lon_met_split = lon_met - 360 ;
            fold = find(lon_met_split < -180 ) ;
            lon_met_split( fold  ) = lon_met_split(fold) + 360;
            lon_met_split = cat(1, lon_met_split, lon_met_split(fold) );
            lon_met_split( fold  ) = [];

            moveme = MPp600_all(fold,:,:);
            MPp600_all_split = cat(1, MPp600_all, moveme);
            MPp600_all_split(fold,:,:) = [];

            moveme = MPp600_mask(fold,:,:);
            MPp600_mask_split = cat(1, MPp600_mask, moveme);
            MPp600_mask_split(fold,:,:) = [];

            moveme = LSp600_all(fold,:,:);
            LSp600_all_split = cat(1, LSp600_all, moveme);
            LSp600_all_split(fold,:,:) = [];

            moveme = LSp600_mask(fold,:,:);
            LSp600_mask_split = cat(1, LSp600_mask, moveme);
            LSp600_mask_split(fold,:,:) = [];

            % loop to plot:

            %for TT =  1:3:length(basetime_MPtracks)
            for TT =  2105:1:2120 %length(basetime_MPtracks)

                %  TT = 2900   % TT = 818;  TT = 300
                %  TT = 1477

                t_mcs = find( floor(basetime_MPtracks(TT)/100) == floor(basetime_mcs/100) ) ;


                % ff = figure('visible','off','Position',[911,450,1395,448]);   %p
                 ff = figure('visible','on','Position',[911,450,1395,448]);   %p

                set(gcf, 'InvertHardCopy', 'off');

                %panel expanders
                aa= -0.05; bb = -0.05; ccr = 0.07; dd = 0.07;
                % lat/lon plot domain
                aaa = 190-360; bbb = 290-360; ccc = 20; ddd = 55;
                %wider:
                aaa = 120-360; bbb = 310-360; ccc = 15; ddd = 65;


                %     ss = subplot(1,1,1);    %p
                %     matlabsux = ss.Position + [aa bb ccr dd];   %p

                ax1 = axes;%('Position',matlabsux);  %p
                ax2 = axes;%('Position',matlabsux);  %p
                ax3 = axes;%('Position',matlabsux);  %p
                ax4 = axes;
                ax5 = axes;
                ax6 = axes;
                ax7 = axes;
                ax8 = axes;
                linkaxes([ax1,ax2,ax3,ax4,ax5,ax6,ax7,ax8],'xy')    %p

                %dualpol_colmap
                contourf(ax1,lon_met-360,lat_met,MPp600_all(:,:,TT)',[-0.0001:0.00001: 0.0001],'LineColor','none')
                %contourf(ax1,lon_met_split,lat_met,MPp600_all_split(:,:,TT)',30,'LineColor','none')
                c = colorbar(ax1,'Position',[0.93 0.168 0.022 0.7],'YTick',[-0.0001 : 0.000025 : 0.0001]);  % attach colorbar to h
                colormap(ax1,flipud(sprite2))
                caxis(ax1,[-0.0001 0.0001])
                hold on


                tmp = cloudtracknumber_LStracks(:,:,TT)'; tmp(isnan(tmp)) = 0;
                contour(ax2,lon_met-360,lat_met,tmp,[0.99:1:1000.99],'m','LineWidth',1);
                %contour(ax2,lon_met,lat_met,cloudtracknumber_LStracks(:,:,TT)',[0.99:1:1000.99],'m','LineWidth',1);
                %contour(ax2,lon_met,lat_met,LSp600_all(:,:,TT)',[0.00001 0.00001],'m','LineWidth',1)
                hold on

                contour(ax3,lon_met-360,lat_met,MPmasks_masked(:,:,TT)',[-1 -0.99],'k','LineWidth',1)
                hold on

                contour(ax4,lon_met-360,lat_met,MPmasks_masked(:,:,TT)',[0.99 1],'k','LineWidth',2)
                hold on

                set(gca,'Color','None')       %p
                set(ax2, 'visible', 'off');   %p
                set(ax2, 'XTick', []);        %p
                set(ax2, 'YTick', []);        %p

                set(gca,'Color','None')       %p
                set(ax3, 'visible', 'off');   %p
                set(ax3, 'XTick', []);        %p
                set(ax3, 'YTick', []);        %p

                contour(ax5,lon_met-360,lat_met,MPmasks_masked_withmcs(:,:,TT)',[0.99 1],'-r','LineWidth',2)

                set(gca,'Color','None')       %p
                set(ax4, 'visible', 'off');   %p
                set(ax4, 'XTick', []);        %p
                set(ax4, 'YTick', []);        %


                currLStracks = unique(cloudtracknumber_LStracks(:,:,TT)) ;
                currLStracks(isnan(currLStracks)) = [];
                %plot MP paths
                for p = 1:length(currLStracks)
                    hold on
                    now = find( basetime_LSstats(:,currLStracks(p)) == basetime_LStracks(TT) );

                    temp_lat = meanlat_LSstats( now, currLStracks(p));
                    temp_lon = meanlon_LSstats( now, currLStracks(p))-360;
                    text(ax7, temp_lon, temp_lat, num2str(currLStracks(p)),'FontSize',15,'Color','m' )
                    %text(ax4, temp_lon, temp_lat, strcat( num2str(currMPtracks(p)),' | ', num2str(temp_lat), ' | ', num2str(temp_lon-360)    ) ,'FontSize',15,'Color','b' )

                    %                 hold on
                    %                 temp_lat = meanlat_MPstats( 1:now, currMPtracks(p));
                    %                 temp_lon = meanlon_MPstats( 1:now, currMPtracks(p));
                    %plot(ax7, temp_lon, temp_lat, '-b' )
                end


                currMPtracks = unique(cloudtracknumber_MPtracks(:,:,TT)) ;
                currMPtracks(isnan(currMPtracks)) = [];
                %plot MP paths
                for p = 1:length(currMPtracks)
                    hold on
                    now = find( basetime_MPstats(:,currMPtracks(p)) == basetime_MPtracks(TT) );

                    temp_lat = meanlat_MPstats( now, currMPtracks(p));
                    temp_lon = meanlon_MPstats( now, currMPtracks(p))-360;
                    text(ax7, temp_lon, temp_lat, num2str(currMPtracks(p)),'FontSize',15,'Color','k' )

                    %text(ax4, temp_lon, temp_lat, strcat( num2str(currMPtracks(p)),' | ', num2str(temp_lat), ' | ', num2str(temp_lon-360)    ) ,'FontSize',15,'Color','b' )
                    %                 hold on
                    %                 temp_lat = meanlat_MPstats( 1:now, currMPtracks(p));
                    %                 temp_lon = meanlon_MPstats( 1:now, currMPtracks(p));
                    %plot(ax7, temp_lon, temp_lat, '-b' )

                end


                set(gca,'Color','None')       %p
                set(ax5, 'visible', 'off');   %p
                set(ax5, 'XTick', []);        %p
                set(ax5, 'YTick', []);        %p


                track = cloudtracknumber_mcs(:,:,t_mcs) ;
                currMCS = unique(track); currMCS(isnan(currMCS))=[];
                if(isempty(currMCS)==0)
                    lon_mcs_flip = lon_mcs;
                    lon_mcs_flip(find(lon_mcs<0)) = lon_mcs_flip(find(lon_mcs<0)) ;
                    contourf(ax7,lon_mcs , lat_mcs, permute(track,[2 1]),[currMCS(1) currMCS(end)],'FaceColor',[1 0 0])%,'LineWidth',6 )
                    %contourf(ax6,lon_mcs_flip, lat_mcs, permute(track,[2 1]),'FaceColor',[1 0 0])%,'LineWidth',6 )
                    if(isempty(currMCS)==0)
                        for p = 1:length(currMCS)
                            temp_lat = meanlat_MCSstats( find( basetime_MCSstats(:,currMCS(p)) == basetime_mcs(t_mcs) ), currMCS(p));
                            temp_lon = meanlon_MCSstats( find( basetime_MCSstats(:,currMCS(p)) == basetime_mcs(t_mcs) ), currMCS(p));
                            text(ax7,temp_lon, temp_lat, num2str(currMCS(p)),'FontSize',15,'Color',[0.5 0 0] )
                        end
                    end

                end


                %figure
                load coastlines
%                 flips = find(coastlon < -20);
%                 fliplon = coastlon;  fliplon(flips) = fliplon(flips);
%                 plot(ax7,fliplon,coastlat,'Color',[0.8 0.5 0.5],'LineWidth',0.75);  % plot(fliplon,coastlat,'.k')

                hold on

                states = readgeotable("usastatehi.shp");
                states{:,4} = states{:,4}; 
                geoshow(ax7,states,'facecolor', 'none', 'MarkerEdgeColor', [0.8 0.5 0.5])
                borders("Canada",'k')
                borders("Mexico",'k')
                borders("Cuba",'k')

                                thin = 5;
                [meshlat meshlon] = meshgrid( lat_met(1:thin:end), lon_met(1:thin:end)-360 );
                quiver(ax8, meshlon, meshlat, U600_bpf(1:thin:end,1:thin:end,TT), V600_bpf(1:thin:end,1:thin:end,TT) ,'k')

                set(gca,'Color','None')       %p
                set(ax6, 'visible', 'off');   %p
                set(ax6, 'XTick', []);        %p
                set(ax6, 'YTick', []);        %p

                set(gca,'Color','None')       %p
                set(ax7, 'visible', 'off');   %p
                set(ax7, 'XTick', []);        %p
                set(ax7, 'YTick', []);        %p

                set(gca,'Color','None')       %p
                set(ax8, 'visible', 'off');   %p
                set(ax8, 'XTick', []);        %p
                set(ax8, 'YTick', []);        %p

                axis([200-360 300-360 20 60])

                title(ax1,['Vorticity -  ',num2str(TT),' - ', char(basetime_met_yymmddhhmmss(TT)) ])

                ttpad =  pad(num2str(TT),4,'left');
                ttpad(find(ttpad == ' ')) = '0';

                mkdir(strcat(outdir,'/png/')) %now done above

                fileoutp2 = horzcat(outdir,'/png/MCS_LS_MP_VOR600_bpf_sm7pt_latlon_',ttpad, '_', char(basetime_met_yymmddhhmmss(TT)));   %now done above

                PNGout2 = horzcat(fileoutp2,'.png');  %now done above, I think?

                outlab = horzcat(outdir,'/png/VECTORS_MCS_LS_MP_VOR600_bpf_sm7pt_latlon_',ttpad, '_', char(basetime_met_yymmddhhmmss(TT)));
                EPSprint = horzcat('print -painters -depsc ',outlab);
                eval([EPSprint]);
                

                saveas(ff,PNGout2)

                close(ff)

                figure
                thin = 5;
                [meshlat meshlon] = meshgrid( lat_met(1:thin:end), lon_met(1:thin:end)-360 );
                quiver(meshlon, meshlat, U600_bpf(1:thin:end,1:thin:end,TT), V600_bpf(1:thin:end,1:thin:end,TT) ,'k')
                axis([200-360 300-360 20 60])


            end




        end







        %     %%%%%%%%%%%%%%%%%%%%%%%
        %     %%% specialty plotting
        %     % specialty plotting
        %     % specialty plotting
        %     % specialty plotting
        %     % specialty plotting
        %     % specialty plotting
        %     %%%%%%%%%%%%%%%%%%%%%%%
        %
        %     dualpol_colmap
        %
        %     if (plotme == 1)
        %
        %
        %         %var name bypasses to adapt to legacy code below:
        %         lon_met = lon_MPtracks;
        %         lat_met = lat_MPtracks;
        %         MPp600_all = MP600;
        %         MPp600_mask = tracknumber_MPtracks;
        %
        %         % wrap map longitudes over -180 deg to center on pacific:
        %         lon_met_split = lon_met - 360 ;
        %         fold = find(lon_met_split < -180 ) ;
        %         lon_met_split( fold  ) = lon_met_split(fold) + 360;
        %         lon_met_split = cat(1, lon_met_split, lon_met_split(fold) );
        %         lon_met_split( fold  ) = [];
        %
        %         moveme = MPp600_all(fold,:,:);
        %         MPp600_all_split = cat(1, MPp600_all, moveme);
        %         MPp600_all_split(fold,:,:) = [];
        %
        %         moveme = MPp600_mask(fold,:,:);
        %         MPp600_mask_split = cat(1, MPp600_mask, moveme);
        %         MPp600_mask_split(fold,:,:) = [];
        %
        %
        %         % loop to plot:
        %
        %         for TT =  810:915 %1:3:length(basetime_MPtracks)
        %
        %             %  TT = 2524    %   TT = 818
        %
        %             t_mcs = find( floor(basetime_MPtracks(TT)/100) == floor(basetime_mcs/100) ) ;
        %
        %
        %             %  ff = figure('visible','off','Position',[911,450,1395,448]);   %p
        %              ff = figure('visible','on','Position',[911,450,1395,448]);   %p
        %
        %             set(gcf, 'InvertHardCopy', 'off');
        %
        %             %panel expanders
        %             aa= -0.05; bb = -0.05; ccr = 0.07; dd = 0.07;
        %             % lat/lon plot domain
        %             aaa = 190-360; bbb = 290-360; ccc = 20; ddd = 55;
        %             %wider:
        %             aaa = 120-360; bbb = 310-360; ccc = 15; ddd = 65;
        %
        %
        %             %     ss = subplot(1,1,1);    %p
        %             %     matlabsux = ss.Position + [aa bb ccr dd];   %p
        %
        %             ax1 = axes;%('Position',matlabsux);  %p
        %             ax2 = axes;%('Position',matlabsux);  %p
        %             ax3 = axes;%('Position',matlabsux);  %p
        %             ax4 = axes;
        %             ax5 = axes;
        %             ax6 = axes;
        %             linkaxes([ax1,ax2,ax3,ax4,ax5,ax6],'xy')    %p
        %
        %             %dualpol_colmap
        %             contourf(ax1,lon_met,lat_met,MPp600_all(:,:,TT)',[-0.0001:0.00001: 0.0001],'LineColor','none')
        %             %contourf(ax1,lon_met_split,lat_met,MPp600_all_split(:,:,TT)',30,'LineColor','none')
        %
        %             c = colorbar(ax1,'Position',[0.93 0.168 0.022 0.7],'YTick',[-0.0001 : 0.000025 : 0.0001]);  % attach colorbar to h
        %             colormap(ax1,flipud(sprite2))
        %
        %
        %             caxis(ax1,[-0.0001 0.0001])
        %             hold on
        %
        %             contour(ax2,lon_met,lat_met,MPmasks_masked(:,:,TT)',[-1 -0.99],'k','LineWidth',1)
        %             hold on
        %
        %
        %             contour(ax3,lon_met,lat_met,MPmasks_masked(:,:,TT)',[0.99 1],'k','LineWidth',2)
        %             hold on
        %
        %             set(gca,'Color','None')       %p
        %             set(ax2, 'visible', 'off');   %p
        %             set(ax2, 'XTick', []);        %p
        %             set(ax2, 'YTick', []);        %p
        %
        %             contour(ax4,lon_met,lat_met,MPmasks_masked_withmcs(:,:,TT)',[0.99 1],'-r','LineWidth',2)
        %
        %             set(gca,'Color','None')       %p
        %             set(ax3, 'visible', 'off');   %p
        %             set(ax3, 'XTick', []);        %p
        %             set(ax3, 'YTick', []);        %
        %
        %
        %
        %             currMPtracks = unique(cloudtracknumber_MPtracks(:,:,TT)) ;
        %             currMPtracks(isnan(currMPtracks)) = [];
        %
        %             for p = 1:length(currMPtracks)
        %                 hold on
        %                 now = find( basetime_MPstats(:,currMPtracks(p)) == basetime_MPtracks(TT) );
        %
        %
        %                 temp_lat = meanlat_MPstats( now, currMPtracks(p));
        %                 temp_lon = meanlon_MPstats( now, currMPtracks(p));
        %                 text(ax4, temp_lon, temp_lat, num2str(currMPtracks(p)),'FontSize',10,'Color','k' )
        %                 %text(ax4, temp_lon, temp_lat, strcat( num2str(currMPtracks(p)),' | ', num2str(temp_lat), ' | ', num2str(temp_lon-360)    ) ,'FontSize',15,'Color','b' )
        %
        %
        %                 hold on
        %                 temp_lat = meanlat_MPstats( 1:now, currMPtracks(p));
        %                 temp_lon = meanlon_MPstats( 1:now, currMPtracks(p));
        %                 plot(ax5, temp_lon, temp_lat, '-b' )
        %
        %             end
        %
        %             set(gca,'Color','None')       %p
        %             set(ax4, 'visible', 'off');   %p
        %             set(ax4, 'XTick', []);        %p
        %             set(ax4, 'YTick', []);        %p
        %
        %
        %             track = cloudtracknumber_mcs(:,:,t_mcs) ;
        %             currMCS = unique(track); currMCS(isnan(currMCS))=[];
        %
        %             %figure; contourf(cloudtracknumber_mcs(:,:,t_mcs)',20) ;%find( cloudtracknumber_mcs(:,:,t_mcs) == currMCS ); fuck = cloudtracknumber_mcs(:,:,t_mcs); fuck(find( cloudtracknumber_mcs(:,:,t_mcs) == currMCS ))
        %
        %
        %             %         quiet = length(isnan(track(:)));
        %             %         if( quiet < length(track(:)) )
        %
        %             if(isempty(currMCS)==0)
        %
        %                 lon_mcs_flip = lon_mcs;
        %                 lon_mcs_flip(find(lon_mcs<0)) = lon_mcs_flip(find(lon_mcs<0)) + 360;
        %                 %contourf(ax6,lon_mcs + 360, lat_mcs, permute(track,[2 1]),[currMCS(1) currMCS(end)],'FaceColor',[1 0 0])%,'LineWidth',6
        %                 surf(ax6,lon_mcs + 360, lat_mcs, permute(track,[2 1]),'EdgeColor','none','FaceColor','r','Facealpha',0.5);
        %
        %                 %contourf(ax5,lon_mcs_flip, lat_mcs, permute(track,[2 1]),'FaceColor',[1 0 0])%,'LineWidth',6 )
        %                 if(isempty(currMCS)==0)
        %                     for p = 1:length(currMCS)
        %                         temp_lat = meanlat_MCSstats( find( basetime_MCSstats(:,currMCS(p)) == basetime_mcs(t_mcs) ), currMCS(p));
        %                         temp_lon = meanlon_MCSstats( find( basetime_MCSstats(:,currMCS(p)) == basetime_mcs(t_mcs) ), currMCS(p));
        %                         text(ax6,temp_lon+360, temp_lat, num2str(currMCS(p)),'FontSize',15,'Color','k' )
        %                     end
        %                 end
        %
        %
        %
        %             end
        %
        %             %figure
        %             load coastlines
        %             flips = find(coastlon < -20);
        %             fliplon = coastlon;  fliplon(flips) = fliplon(flips) + 360;
        %             plot(ax5,fliplon,coastlat,'Color',[0.8 0 0.5],'LineWidth',0.75);  % plot(fliplon,coastlat,'.k')
        %
        %
        %             set(gca,'Color','None')       %p
        %             set(ax5, 'visible', 'off');   %p
        %             set(ax5, 'XTick', []);        %p
        %             set(ax5, 'YTick', []);        %p
        %
        %
        %             set(gca,'Color','None')       %p
        %             set(ax6, 'visible', 'off');   %p
        %             set(ax6, 'XTick', []);        %p
        %             set(ax6, 'YTick', []);        %p
        %
        %             axis([240 280 25 45])
        %
        %             title(ax1,['Vorticity -  ', char(basetime_met_yymmddhhmmss(TT)) ])
        %
        %             ttpad =  pad(num2str(TT),4,'left');
        %             ttpad(find(ttpad == ' ')) = '0';
        %
        %             mkdir(strcat(outdir,'/png/')) %now done above
        %
        %             fileoutp2 = horzcat(outdir,'/png/VOR600_bpf_sm7pt_MASKED_latlon_',ttpad, '_', char(basetime_met_yymmddhhmmss(TT)));   %now done above
        %
        %             PNGout2 = horzcat(fileoutp2,'.png');  %now done above, I think?
        %
        %             saveas(ff,PNGout2)
        %
        %             close(ff)
        %
        %         end
        %
        %     end




        disp('   ')
        disp(' Saving output for ')
        disp(matout)
        tic

        % matout = '/Volumes/LaCie/WACCEM/datafiles/Bandpass/2004_vorstats_masks_zone_v5_tester.mat'

        %matout = strcat(rootdir,'2012_vorstats_masks_zone.mat');   %now done above
        save(matout,'duration_MPstats','area_MPstats','basetime_MPstats','meanlat_MPstats','meanlon_MPstats','status_MPstats','basetime_MPstats_met_yymmddhhmmss',...
            'dAdt_MPstats','MPtracks_perMCS','maxVOR600_MPstats', 'maxW600bpf_MPstats', 'maxW600_MPstats',...
            ...
            'duration_LSstats','area_LSstats','basetime_LSstats','meanlat_LSstats','meanlon_LSstats','status_LSstats','basetime_LSstats_met_yymmddhhmmss', 'maxVOR600_LSstats', ...
            'MASK_KEEPERS_LS','MASK_TOSSERS_LS','LStracks_perMCS','LS_with_MCSs','LS_without_MCSs','LSmasks_masked','LSmasks_masked_withmcs',...
            'LStracks_perMP','LSs_with_MP','LSs_without_MP',...
            ...
            'duration_MCSstats','basetime_MCSstats','status_MCSstats','basetime_MCSstats_met_yymmddhhmmss','pflon_MCSstats','pflat_MCSstats','pfarea_MCSstats', ...
            'dAdt_MCSstats','pfrainrate_MCSstats','speed_MCSstats','dirmotion_MCSstats','meanlat_MCSstats','meanlon_MCSstats',...
            'totalrain_MCSstats','totalheavyrain_MCSstats','convrain_MCSstats','stratrain_MCSstats','pf_maxrainrate_MCSstats','pf_accumrain_MCSstats','pf_accumrainheavy_MCSstats','rainrate_heavyrain_MCSstats', ...
            'maxW600bpf_MCSstats','maxW600_MCSstats','MASK_TOSSERS_MCS','MASK_KEEPERS_MCS', 'pf_convrate_MCSstats', 'pf_stratrate_MCSstats', 'pf_convarea_MCSstats', 'pf_stratarea_MCSstats', ...
            'pfETH10_MCSstats', 'pfETH30_MCSstats', 'pfETH40_MCSstats', 'pfETH45_MCSstats', 'pfETH50_MCSstats', 'pfcca40_MCSstats', 'pfcca45_MCSstats', 'pfcca50_MCSstats',...
            ...
            'MASK_KEEPERS_MP','MASK_TOSSERS_MP','MASK_no_merge_or_split','MASKS_ALL','MPmasks_masked_withmcs','MPmasks_masked',...
            'MP_with_MCSs','MP_without_MCSs','MP_other','MP_no_merge_or_split',...
            'MCSstatsfile', 'MPstatsf', 'rootdir',...
            'MotionX_MPstats','MotionY_MPstats','MotionX_MCSstats','MotionY_MCSstats','MotionX_LSstats','MotionY_LSstats', ...
            ...
            'meanMUCAPE_MPstats', 'maxMUCAPE_MPstats', 'meanMUCIN_MPstats',...
            'minMUCIN_MPstats', 'meanMULFC_MPstats', 'meanMUEL_MPstats', 'meanPW_MPstats', 'maxPW_MPstats', 'minPW_MPstats',...
            'meanshearmag0to2_MPstats', 'maxshearmag0to2_MPstats', 'meanshearmag0to6_MPstats', 'maxshearmag0to6_MPstats', 'meanshearmag2to9_MPstats', 'maxshearmag2to9_MPstats', ...
            'meanOMEGA600_MPstats', 'minOMEGA600_MPstats', 'minOMEGAsub600_MPstats', 'meanVIWVD_MPstats', 'minVIWVD_MPstats', ...
            'maxVIWVD_MPstats', 'meanDIV750_MPstats', 'minDIV750_MPstats', 'minDIVsub600_MPstats',...
            'meanWNDSPD600', 'meanWNDDIR600', ...
            '-v7.3')

        %'meanPW_MPstats','maxMUCAPE_MPstats','maxVIWVConv_MPstats', ... 'meanPW_MCSstats','maxMUCAPE_MCSstats','maxVIWVConv_MCSstats',
        %

        % 'Cy_MCSstats','Cx_MCSstats' 'MotionX_MPstats','MotionY_MPstats' 'MotionX_MCSstats','MotionY_MCSstats',
        toc

        disp( '      ')
        disp(' Doneski with year ')
        disp( YYYY )
        disp( '      ')

    end

end% overlaps
