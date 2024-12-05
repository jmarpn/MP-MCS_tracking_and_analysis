


%%%%%%%%%%
%%%%%%%%%%  Run this after stepping thru
%%%%%%%%%%  .../PROJECTS/WACCEM/Code/VORTbpf_stats_compilation_COMMONCORE_v6d_violins.m
%%%%%%%%%%

%%% violin version

imout = '/Users/marq789/Documents/PROJECTS/WACCEM/articles/MyArticle/';

xs = 0.5;
xf = 3.5;
figure('units','normalized','outerposition',[0 0 1 1])

%subplot(3,3,1)
ha = tight_subplot(3, 3, [.05 .03],[.1 .1],[.1 .1])

axes(ha(1))
ys = 0;
yf = 60;
blah = MCS_withLS_Duration(:); blah(isnan(MCS_withLS_Duration(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPDuration_list(:); blah(isnan(MCSwithMPDuration_list(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPDuration_list; blah(isnan(MCSwithoutMPDuration_list)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
title('MCS lifetime duration (hr)')
%exp = {'','MCS with LS','MCS with MP','MCS alone',''};
exp = {'','','','',''};
set(gca,'xtick',[0:3],'xticklabel',exp)


%percent diff from LS:
LS_vs_MP = 100 * ( mean(MCS_withLS_Duration(:),'omitnan') - mean(MCSwithMPDuration_list(:),'omitnan') ) / mean([MCSwithMPDuration_list(:);MCS_withLS_Duration(:)],'omitnan')
MP_vs_UN = 100 * ( mean(MCSwithMPDuration_list(:),'omitnan') - mean(MCSwithoutMPDuration_list(:),'omitnan') ) / mean([MCSwithoutMPDuration_list(:);MCSwithMPDuration_list(:)],'omitnan')
LS_vs_UN = 100 * ( mean(MCS_withLS_Duration(:),'omitnan') - mean(MCSwithoutMPDuration_list(:),'omitnan') ) / mean([MCSwithoutMPDuration_list(:);MCS_withLS_Duration(:)],'omitnan')



axes(ha(2))
%subplot(3,3,2)
ys = 0;
yf = 250000;
exp = {'','LS-born','MP-born','unforced MCS',''};
blah = MCS_withLS_maxareapf(:); blah(isnan(MCS_withLS_maxareapf(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPareapf_list(:); blah(isnan(MCSwithMPareapf_list(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPareapf_list; blah(isnan(MCSwithoutMPareapf_list)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
%exp = {'','MCS with LS','MCS with MP','MCS alone',''};
exp = {'','','','',''};
set(gca,'xtick',[0:3],'xticklabel',exp)
title('MCS max lifetime rain area (km^2)')

%percent diff from LS:
LS_vs_MP = 100 * ( mean(MCS_withLS_maxareapf(:),'omitnan') - mean(MCSwithMPareapf_list(:),'omitnan') ) / mean([MCSwithMPareapf_list(:);MCS_withLS_maxareapf(:)],'omitnan')
LS_vs_UN = 100 * ( mean(MCS_withLS_maxareapf(:),'omitnan') - mean(MCSwithoutMPareapf_list(:),'omitnan') ) / mean([MCSwithoutMPareapf_list(:);MCS_withLS_maxareapf(:)],'omitnan')
MP_vs_UN = 100 * ( mean(MCSwithMPareapf_list(:),'omitnan') - mean(MCSwithoutMPareapf_list(:),'omitnan') ) / mean([MCSwithoutMPareapf_list(:);MCSwithMPareapf_list(:)],'omitnan')



axes(ha(3))
% subplot(3,3,3)
ys = 0;
yf = 30000000000000;
exp = {'','LS-born','MP-born','unforced MCS',''};
blah = MCSwithLStotmass(:); blah(isnan(MCSwithLStotmass(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPtotmass_list(:); blah(isnan(MCSwithMPtotmass_list(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPtotmass_list; blah(isnan(MCSwithoutMPtotmass_list)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
%exp = {'','MCS with LS','MCS with MP','MCS alone',''};
exp = {'','','','',''};
set(gca,'xtick',[0:3],'xticklabel',exp)
title('MCS lifetime accumulated rain mass (kg)')

%percent diff from LS:
LS_vs_MP = 100 * ( mean(MCSwithLStotmass(:),'omitnan') - mean(MCSwithMPtotmass_list(:),'omitnan') ) / mean([MCSwithMPtotmass_list(:);MCSwithLStotmass(:)],'omitnan')
LS_vs_UN = 100 * ( mean(MCSwithLStotmass(:),'omitnan') - mean(MCSwithoutMPtotmass_list(:),'omitnan') ) / mean([MCSwithoutMPtotmass_list(:);MCSwithLStotmass(:)],'omitnan')
MP_vs_UN = 100 * ( mean(MCSwithMPtotmass_list(:),'omitnan') - mean(MCSwithoutMPtotmass_list(:),'omitnan') ) / mean([MCSwithoutMPtotmass_list(:);MCSwithMPtotmass_list(:)],'omitnan')


axes(ha(5))
%subplot(3,3,5)
ys = 0;
yf = 75000;
exp = {'','LS-born','MP-born','unforced MCS',''};
blah = MCSwithLSaccumhvy(:); blah(isnan(MCSwithLSaccumhvy(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPhvyaccum(:); blah(isnan(MCSwithMPhvyaccum(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPhvyaccum; blah(isnan(MCSwithoutMPhvyaccum)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
%exp = {'','MCS with LS','MCS with MP','MCS alone',''};
exp = {'','','','',''};
set(gca,'xtick',[0:3],'xticklabel',exp)
 title('MCS lifetime accumulated rain mass [heavy rain] (kg)')

MP_vs_UN = 100 * ( mean(MCSwithMPhvyaccum(:),'omitnan') - mean(MCSwithoutMPhvyaccum(:),'omitnan') ) ./  mean([MCSwithMPhvyaccum(:);MCSwithoutMPhvyaccum(:)],'omitnan') 



axes(ha(6))
%subplot(3,3,4)
ys = 5;
yf = 40;
exp = {'','LS-born','MP-born','unforced MCS',''};
blah = MCSwithLSspeed(:); blah(isnan(MCSwithLSspeed(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPmcsspeed_list(:); blah(isnan(MCSwithMPmcsspeed_list(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPmcsspeed_list; blah(isnan(MCSwithoutMPmcsspeed_list)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
%exp = {'','MCS with LS','MCS with MP','MCS alone',''};
exp = {'','','','',''};
set(gca,'xtick',[0:3],'xticklabel',exp)
title('Mean lifetime MCS speed (m/s)')

%percent diff from LS:
LS_vs_MP = 100 * ( mean(MCSwithLSspeed(:),'omitnan') - mean(MCSwithMPmcsspeed_list(:),'omitnan') ) / mean([MCSwithMPmcsspeed_list(:); MCSwithLSspeed(:)],'omitnan')
LS_vs_UN = 100 * ( mean(MCSwithLSspeed(:),'omitnan') - mean(MCSwithoutMPmcsspeed_list(:),'omitnan') ) / mean([MCSwithoutMPmcsspeed_list(:); MCSwithLSspeed(:)],'omitnan')
MP_vs_UN = 100 * ( mean(MCSwithMPmcsspeed_list(:),'omitnan') - mean(MCSwithoutMPmcsspeed_list(:),'omitnan') ) / mean([MCSwithoutMPmcsspeed_list(:); MCSwithMPmcsspeed_list(:)],'omitnan')




axes(ha(4))
%subplot(3,3,6)
ys = 0;
yf = 120000;
exp = {'','LS-born','MP-born','unforced MCS',''};
blah = MCSwithLSdadt(:); blah(isnan(MCSwithLSdadt(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPdadt_list(:); blah(isnan(MCSwithMPdadt_list(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPdadt_list; blah(isnan(MCSwithoutMPdadt_list)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
%exp = {'','MCS with LS','MCS with MP','MCS alone',''};
exp = {'','','','',''};
set(gca,'xtick',[0:3],'xticklabel',exp)
title('Max rain area growth rate in first 6 hr of MCS lifetime (km^2 hr^-^1)')


axes(ha(7))
% subplot(3,3,7)
ys = 0;
yf = 20;
exp = {'','LS-born','MP-born','unforced MCS',''};
blah = MCSwithLSeth50(:); blah(isnan(MCSwithLSeth50(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPmax50eth(:); blah(isnan(MCSwithMPmax50eth(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPmax50eth; blah(isnan(MCSwithoutMPmax50eth)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
%exp = {'','MCS with LS','MCS with MP','MCS alone',''};
exp = {'','','','',''};
set(gca,'xtick',[0:3],'xticklabel',exp)
title('MCS lifetime max 50 dBZ echo top (km)')


axes(ha(8))
% subplot(3,3,8)
ys = 5;
yf = 20;
exp = {'','LS-born','MP-born','unforced MCS',''};
blah = MCSwithLSeth30(:); blah(isnan(MCSwithLSeth30(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPmax30eth(:); blah(isnan(MCSwithMPmax30eth(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPmax30eth; blah(isnan(blah)) = [];
blah = randsample(MCSwithoutMPmax30eth,floor(length(MCSwithoutMPmax30eth)/4)); blah(isnan(blah)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
%exp = {'','MCS with LS','MCS with MP','MCS alone',''};
exp = {'','','','',''};
set(gca,'xtick',[0:3],'xticklabel',exp)
title('Max 30 dBZ echo top in first 3 hr of MCS lifetime (km) ')


outlab = horzcat(imout,'/Violin1_LSMPMCS_genprecip',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);




%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%   now do stat sig table
%%%%%%%%%%%%%%%%%%%%%%%%%%%
alvl = 0.05;

% vars_LS = { "MCS_withLS_Duration",   "MCS_withLS_maxareapf",   "MCSwithLStotmass",    "MCSwithLSspeed",     "MCSwithLSaccumhvy", ...
%             "MCSwithLSdadt",   "MCSwithLSeth50",     "MCSwithLSeth30" };
% 
% vars_MP = { "MCSwithMPDuration_list",   "MCSwithMPareapf_list",  "MCSwithMPtotmass_list",   "MCSwithMPmcsspeed_list",   "MCSwithMPhvyaccum", ...
%             "MCSwithMPdadt_list",    "MCSwithMPmax50eth",    "MCSwithMPmax30eth" };
% 
% vars_NO = { "MCSwithoutMPDuration_list",  "MCSwithoutMPareapf_list",   "MCSwithoutMPtotmass_list",  "MCSwithoutMPmcsspeed_list",  "MCSwithoutMPhvyaccum", ...
%             "MCSwithoutMPdadt_list",   "MCSwithoutMPmax50eth",  "MCSwithoutMPmax30eth"};
% 
% VARS = [ "MCS duration"; "MCS max area"; "MCS accum rain mass"; "MCS speed"; "MCS accum hvy rain"; "MCS max growth rate"; "MCS 50dBZ ETH"; "MCS 30dBZ ETH" ];
% comps = {"LS-MP","LS-None","MP-None"};
% 
% dummy = ['-------'; '-------'; '-------'; '-------'; '-------'; '-------'; '-------'; '-------'];
% LSvsMP = dummy;
% LSvsUF = dummy;
% MPvsUF = dummy;
% 
% for va = 1:length(vars_LS)
% 
%     [sh,p]   = kstest2( eval(string(vars_LS(va))) , eval(string( vars_MP(va) )), 'Alpha', alvl ) ;
%     [p2,sh2] = ranksum( eval(string(vars_LS(va))) , eval(string( vars_MP(va) )), 'Alpha', alvl ) ;
%     if( sh == 0 & sh2 == 0 )
%         LSvsMP(va,:) = '-------';
%     elseif( sh == 1 & sh2 == 0 )
%         LSvsMP(va,:) = 'K-S    ';
%     elseif( sh == 0 & sh2 == 1 )
%         LSvsMP(va,:) = 'WRS    ';
%     elseif( sh == 1 & sh2 == 1 )
%         LSvsMP(va,:) = 'K-S,WRS';
%     end
% 
%     [sh,p]   = kstest2( eval(string(vars_LS(va))), eval(string( vars_NO(va) )),'Alpha',alvl ) ;
%     [p2,sh2] = ranksum( eval(string(vars_LS(va))), eval(string( vars_NO(va) )),'Alpha',alvl ) ;
%     if( sh == 0 & sh2 == 0 )
%         LSvsUF(va,:) = '-------';
%     elseif( sh == 1 & sh2 == 0 )
%         LSvsUF(va,:) = 'K-S    ';
%     elseif( sh == 0 & sh2 == 1 )
%         LSvsUF(va,:) = 'WRS    ';
%     elseif( sh == 1 & sh2 == 1 )
%         LSvsUF(va,:) = 'K-S,WRS';
%     end
% 
%     [sh,p]   = kstest2( eval(string(vars_MP(va))), eval(string( vars_NO(va) )),'Alpha',alvl ) ;
%     [p2,sh2] = ranksum( eval(string(vars_MP(va))), eval(string( vars_NO(va) )),'Alpha',alvl ) ;
%     if( sh == 0 & sh2 == 0 )
%         MPvsUF(va,:) = '-------';
%     elseif( sh == 1 & sh2 == 0 )
%         MPvsUF(va,:) = 'K-S    ';
%     elseif( sh == 0 & sh2 == 1 )
%         MPvsUF(va,:) = 'WRS    ';
%     elseif( sh == 1 & sh2 == 1 )
%         MPvsUF(va,:) = 'K-S,WRS';
%     end
% 
% end
% 
% SigDiffTable = table(VARS,LSvsMP,LSvsUF,MPvsUF)  ;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% reviwer2 comment:  wang-clone histograms to compare to Song et al. 2021:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
ff = figure('position',[231,295,652,416]);

title(' Max rainfall area of MCSs.','FontSize',15)
edges=[0:6000:180000];
hold on
[h1,b] = hist(MCSwithMPareapf_list,edges) ;  blah1 =  h1/(sum(h1));
b1 = bar(b,blah1,1,'FaceColor',[1 0.5 0]);
alpha 0.7
hold on

%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(MCSwithoutMPareapf_list,edges) ;  blah2 =  h1/(sum(h1));
b2 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
alpha 0.7
hold on

plot(median(MCSwithMPareapf_list,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPareapf_list,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
plot(median(MCSwithoutMPareapf_list,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
plot(mean(MCSwithoutMPareapf_list,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
alvl = 0.05;

xticks( [0:6000:180000] )
axis([0 180000 0 0.20 ])



outlab = horzcat(imout,'/MCSarea_hist_withwithoutMP_myset',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);





%histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
ff = figure('position',[231,295,652,416]);

title(' Accumulated rainfall mass of MCSs.','FontSize',15)
edges=[0:500000000000:15000000000000];
hold on
[h1,b] = hist(MCSwithMPtotmass_list,edges) ;  blah1 =  h1/(sum(h1));
b1 = bar(b,blah1,1,'FaceColor',[1 0.5 0]);
alpha 0.7
hold on

%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(MCSwithoutMPtotmass_list,edges) ;  blah2 =  h1/(sum(h1));
b2 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
alpha 0.7
hold on

plot(median(MCSwithMPtotmass_list,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPtotmass_list,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
plot(median(MCSwithoutMPtotmass_list,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
plot(mean(MCSwithoutMPtotmass_list,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
alvl = 0.05;

xticks( [0:500000000000:15000000000000] )
axis([0 15000000000000 0 0.20 ])

outlab = horzcat(imout,'/MCSmass_hist_withwithoutMP_myset',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%       Convective  vs Stratiform breakdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


xs = 0.5;
xf = 3.5;
figure('units','normalized','outerposition',[0 0 1 1])

ha = tight_subplot(3, 3, [.05 .03],[.1 .1],[.1 .1])

axes(ha(1))
ys = 0;
yf = 5000000000000;
exp = {'','LS-born','MP-born','unforced MCS',''};
exp = {'','','','',''};
blah = MCSwithLSconvmass(:); blah(isnan(MCSwithLSconvmass(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPconvmass_list(:); blah(isnan(MCSwithMPconvmass_list(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPconvmass_list; blah(isnan(MCSwithoutMPconvmass_list)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp)
title('MCS lifetime accumulated convective rain mass (kg)')

%percent diff from LS:
LS_vs_MP = 100 * ( mean(MCSwithLSconvmass(:),'omitnan') - mean(MCSwithMPconvmass_list(:),'omitnan') ) /  mean([MCSwithMPconvmass_list(:); MCSwithLSconvmass(:)],'omitnan')   
LS_vs_UN = 100 * ( mean(MCSwithLSconvmass(:),'omitnan') - mean(MCSwithoutMPconvmass_list(:),'omitnan') ) / mean([MCSwithoutMPconvmass_list(:); MCSwithLSconvmass(:)],'omitnan') 
MP_vs_UN = 100 * ( mean(MCSwithMPconvmass_list(:),'omitnan') - mean(MCSwithoutMPconvmass_list(:),'omitnan') ) / mean([MCSwithoutMPconvmass_list(:); MCSwithMPconvmass_list(:)],'omitnan') 



axes(ha(2))
ys = 0;
yf = 15000000000000;
exp = {'','LS-born','MP-born','unforced MCS',''};
exp = {'','','','',''};
blah = MCSwithLSstratmass(:); blah(isnan(MCSwithLSstratmass(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPstratmass_list(:); blah(isnan(MCSwithMPstratmass_list(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPstratmass_list; blah(isnan(MCSwithoutMPstratmass_list)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp)
title('MCS lifetime accumulated stratiform rain mass (kg)')

MP_vs_UN = 100 * ( mean(MCSwithMPstratmass_list(:),'omitnan') - mean(MCSwithoutMPstratmass_list(:),'omitnan') ) /  mean([MCSwithoutMPstratmass_list(:); MCSwithMPstratmass_list(:)],'omitnan') 



axes(ha(3))
ys = 0;
yf = 1.5;
exp = {'','LS-born','MP-born','unforced MCS',''};
exp = {'','','','',''};
blah = MCSwithLScsratmass(:); blah(isnan(MCSwithLScsratmass(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPcsrat_mass(:); blah(isnan(MCSwithMPcsrat_mass(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPcsrat_mass; blah(isnan(MCSwithoutMPcsrat_mass)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp)
title('Ratio: Convective/Stratiform lifetime accumulated rain')

LS_vs_MP = 100 * ( mean(MCSwithLScsratmass(:),'omitnan') - mean(MCSwithMPcsrat_mass(:),'omitnan') ) ./  mean([MCSwithMPcsrat_mass(:); MCSwithLScsratmass(:)],'omitnan')   
LS_vs_UN = 100 * ( mean(MCSwithLScsratmass(:),'omitnan') - mean(MCSwithoutMPcsrat_mass(:),'omitnan') ) ./ mean([MCSwithoutMPcsrat_mass(:); MCSwithLScsratmass(:)],'omitnan') 
MP_vs_UN = 100 * ( mean(MCSwithMPcsrat_mass(:),'omitnan') - mean(MCSwithoutMPcsrat_mass(:),'omitnan') ) ./ mean([MCSwithoutMPcsrat_mass(:); MCSwithMPcsrat_mass(:)],'omitnan') 

% LS_vs_MP  = 100*( mean(MCSwithLScsratmass(:),'omitnan') - mean(MCSwithMPcsrat_mass(:),'omitnan') ) ./  (      mean(MCSwithMPcsrat_mass(:),'omitnan') + mean(MCSwithLScsratmass(:),'omitnan')  )
% MP_vs_UN  = 100*( mean(MCSwithMPcsrat_mass(:),'omitnan') - mean(MCSwithoutMPcsrat_mass(:),'omitnan') ) ./  (      mean(MCSwithMPcsrat_mass(:),'omitnan') + mean(MCSwithoutMPcsrat_mass(:),'omitnan')  )


axes(ha(4))
ys = 0;
yf = 50000;
exp = {'','LS-born','MP-born','unforced MCS',''};
exp = {'','','','',''};
blah = MCSwithLSconvarea(:); blah(isnan(MCSwithLSconvarea(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPconvarea(:); blah(isnan(MCSwithMPconvarea(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPconvarea; blah(isnan(MCSwithoutMPconvarea)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp)
title('MCS lifetime max convective rain area (km^2)')


axes(ha(5))
ys = 0;
yf = 200000;
exp = {'','LS-born','MP-born','unforced MCS',''};
exp = {'','','','',''};
blah = MCSwithLSstratarea(:); blah(isnan(MCSwithLSstratarea(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPstratarea(:); blah(isnan(MCSwithMPstratarea(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPstratarea; blah(isnan(MCSwithoutMPstratarea)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp)
title('MCS lifetime max stratiform rain area (km^2)')


axes(ha(6))
ys = 0;
yf = 1.0;
exp = {'','LS-born','MP-born','unforced MCS',''};
exp = {'','','','',''};
blah = MCSwithLScsratarea(:); blah(isnan(MCSwithLScsratarea(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPcsrat_area(:); blah(isnan(MCSwithMPcsrat_area(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPcsrat_area; blah(isnan(MCSwithoutMPcsrat_area)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp)
title('Ratio: Convective/Stratiform lifetime max rain area')

% LS_vs_MP  = 100*( mean(MCSwithLScsratarea(:),'omitnan') - mean(MCSwithMPcsrat_area(:),'omitnan') ) ./  (      mean(MCSwithMPcsrat_area(:),'omitnan') + mean(MCSwithLScsratarea(:),'omitnan')  )
% MP_vs_UN  = 100*( mean(MCSwithMPcsrat_area(:),'omitnan') - mean(MCSwithoutMPcsrat_area(:),'omitnan') ) ./  (      mean(MCSwithMPcsrat_area(:),'omitnan') + mean(MCSwithoutMPcsrat_area(:),'omitnan')  )
% LS_vs_UN  = 100*( mean(MCSwithLScsratarea(:),'omitnan') - mean(MCSwithoutMPcsrat_area(:),'omitnan') ) ./  (      mean(MCSwithoutMPcsrat_area(:),'omitnan') + mean(MCSwithLScsratarea(:),'omitnan')  )

LS_vs_MP = 100 * ( mean(MCSwithLScsratarea(:),'omitnan') - mean(MCSwithMPcsrat_area(:),'omitnan') ) ./  mean([MCSwithMPcsrat_area(:); MCSwithLScsratarea(:)],'omitnan')   
LS_vs_UN = 100 * ( mean(MCSwithLScsratarea(:),'omitnan') - mean(MCSwithoutMPcsrat_area(:),'omitnan') ) ./ mean([MCSwithoutMPcsrat_area(:); MCSwithLScsratarea(:)],'omitnan') 
MP_vs_UN = 100 * ( mean(MCSwithMPcsrat_area(:),'omitnan') - mean(MCSwithoutMPcsrat_area(:),'omitnan') ) ./ mean([MCSwithoutMPcsrat_area(:); MCSwithMPcsrat_area(:)],'omitnan') 




axes(ha(7))
ys = 0;
yf = 100;
exp = {'','LS-born','MP-born','unforced MCS',''};
exp = {'','','','',''};
blah = MCSwithLSconvrate(:); blah(isnan(MCSwithLSconvrate(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPconvrate(:); blah(isnan(MCSwithMPconvrate(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPconvrate; blah(isnan(MCSwithoutMPconvrate)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp)
title('MCS lifetime max convective rain rate (mm hr^-^1)')


axes(ha(8))
ys = 5;
yf = 80;
exp = {'','LS-born','MP-born','unforced MCS',''};
exp = {'','','','',''};
blah = MCSwithLSstratrate(:); blah(isnan(MCSwithLSstratrate(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPstratrate(:); blah(isnan(MCSwithMPstratrate(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPstratrate; blah(isnan(MCSwithoutMPstratrate)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp)
title('MCS lifetime max stratiform rain rate (mm hr^-^1)')


axes(ha(9))
ys = 0.5;
yf = 2.0;
exp = {'','LS-born','MP-born','unforced MCS',''};
exp = {'','','','',''};
blah = MCSwithLScsratrate(:); blah(isnan(MCSwithLScsratrate(:))) = [];
violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
hold on
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blah = MCSwithMPcsrat_rate(:); blah(isnan(MCSwithMPcsrat_rate(:))) = [];
violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
blah = MCSwithoutMPcsrat_rate; blah(isnan(MCSwithoutMPcsrat_rate)) = [];
violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blah,25); p75 = prctile(blah,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp)
title('Ratio: Convective/Stratiform lifetime max rain rate')



outlab = horzcat(imout,'/Violin2_LSMPMCS_ConvStrat',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);








%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%   now do stat sig table
%%%%%%%%%%%%%%%%%%%%%%%%%%%

alvl = 0.05;

vars_LS = { "MCS_withLS_Duration",   "MCS_withLS_maxareapf",   "MCSwithLStotmass",    "MCSwithLSspeed",     "MCSwithLSaccumhvy", ...
            "MCSwithLSdadt",   "MCSwithLSeth50",     "MCSwithLSeth30", "MCSwithLSconvmass", "MCSwithLSstratmass", "MCSwithLScsratmass", ...
            "MCSwithLSconvarea", "MCSwithLSstratarea", "MCSwithLScsratarea", ...
            "MCSwithLSconvrate", "MCSwithLSstratrate", "MCSwithLScsratrate" };

vars_MP = { "MCSwithMPDuration_list",   "MCSwithMPareapf_list",  "MCSwithMPtotmass_list",   "MCSwithMPmcsspeed_list",   "MCSwithMPhvyaccum", ...
            "MCSwithMPdadt_list",    "MCSwithMPmax50eth",    "MCSwithMPmax30eth", "MCSwithMPconvmass_list", "MCSwithMPstratmass_list", "MCSwithMPcsrat_mass", ...
            "MCSwithMPconvarea",      "MCSwithMPstratarea",      "MCSwithMPcsrat_area", ...
            "MCSwithMPconvrate",      "MCSwithMPstratrate",      "MCSwithMPcsrat_rate" };

vars_NO = { "MCSwithoutMPDuration_list",  "MCSwithoutMPareapf_list",   "MCSwithoutMPtotmass_list",  "MCSwithoutMPmcsspeed_list",  "MCSwithoutMPhvyaccum", ...
            "MCSwithoutMPdadt_list",   "MCSwithoutMPmax50eth",  "MCSwithoutMPmax30eth", "MCSwithoutMPconvmass_list", "MCSwithoutMPstratmass_list", "MCSwithoutMPcsrat_mass", ...
            "MCSwithoutMPconvarea",      "MCSwithoutMPstratarea",      "MCSwithoutMPcsrat_area", ...
            "MCSwithoutMPconvrate",      "MCSwithoutMPstratrate",      "MCSwithoutMPcsrat_rate" };

VARS = [ "MCS duration"; "MCS max area"; "MCS accum rain mass"; "MCS speed"; "MCS accum hvy rain"; "MCS max growth rate"; ...
         "MCS 50dBZ ETH"; "MCS 30dBZ ETH"; "Accum conv rain"; "Accum strat rain"; "Accum rain C/S"; ...
         "Max conv area"; "Max strat area"; "Max area C/S"; ...
         "Max conv rain rate"; "Max strat rain rate"; "Max rain rate C/S" ];

comps = {"LS-MP","LS-None","MP-None"};

dummy = ['-------'; '-------'; '-------'; '-------'; '-------'; '-------'; '-------'; '-------';  ...
         '-------'; '-------'; '-------'; '-------'; '-------'; '-------'; '-------'; '-------';'-------'];
LSvsMP = dummy;
LSvsUF = dummy;
MPvsUF = dummy;

for va = 1:length(vars_LS)

    [sh,p]   = kstest2( eval(string(vars_LS(va))) , eval(string( vars_MP(va) )), 'Alpha', alvl ) ;
    [p2,sh2] = ranksum( eval(string(vars_LS(va))) , eval(string( vars_MP(va) )), 'Alpha', alvl ) ;
    if( sh == 0 & sh2 == 0 )
        LSvsMP(va,:) = '-------';
    elseif( sh == 1 & sh2 == 0 )
        LSvsMP(va,:) = 'K-S    ';
    elseif( sh == 0 & sh2 == 1 )
        LSvsMP(va,:) = 'WRS    ';
    elseif( sh == 1 & sh2 == 1 )
        LSvsMP(va,:) = 'K-S,WRS';
    end

    [sh,p]   = kstest2( eval(string(vars_LS(va))), eval(string( vars_NO(va) )),'Alpha',alvl ) ;
    [p2,sh2] = ranksum( eval(string(vars_LS(va))), eval(string( vars_NO(va) )),'Alpha',alvl ) ;
    if( sh == 0 & sh2 == 0 )
        LSvsUF(va,:) = '-------';
    elseif( sh == 1 & sh2 == 0 )
        LSvsUF(va,:) = 'K-S    ';
    elseif( sh == 0 & sh2 == 1 )
        LSvsUF(va,:) = 'WRS    ';
    elseif( sh == 1 & sh2 == 1 )
        LSvsUF(va,:) = 'K-S,WRS';
    end

    [sh,p]   = kstest2( eval(string(vars_MP(va))), eval(string( vars_NO(va) )),'Alpha',alvl ) ;
    [p2,sh2] = ranksum( eval(string(vars_MP(va))), eval(string( vars_NO(va) )),'Alpha',alvl ) ;
    if( sh == 0 & sh2 == 0 )
        MPvsUF(va,:) = '-------';
    elseif( sh == 1 & sh2 == 0 )
        MPvsUF(va,:) = 'K-S    ';
    elseif( sh == 0 & sh2 == 1 )
        MPvsUF(va,:) = 'WRS    ';
    elseif( sh == 1 & sh2 == 1 )
        MPvsUF(va,:) = 'K-S,WRS';
    end

end

SigDiffTable = table(VARS,LSvsMP,LSvsUF,MPvsUF)  ;






%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment    bonus fig
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment   break up MCS metrics into +/- 33 percitles
%%%%%%%%%                      of MP vorticity and area
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment


alvl = 0.05;


%for at MCSI period only:
vortvar = MP_vorticity_MCSI_4violins  ;
areavar = MP_area_MCSI_4violins  ;
%MCS_maxarea_MCSI_4violins        ; %= maxareapf_MCSstats_ALLYRS .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
%MCS_totalrainmass_MCSI_4violins  ; %= totalrainmass_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
%MCS_duration_4violins            ; %= duration_MCSstats_ALLYRS .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;

vort66 = prctile(vortvar(:),66)
vort33 = prctile(vortvar(:),33)
area66 = prctile(areavar(:),66)
area33 = prctile(areavar(:),33)

vortLO = find( vortvar <= vort33 );
vortMD = find( vortvar > vort33  &   vortvar <= vort66   );
vortHI = find( vortvar > vort66 );

areaLO = find( areavar <= area33 );
areaMD = find( areavar > area33  &   areavar <= area66   );
areaHI = find( areavar > area66 );


mcsarea_vLO = MCS_maxarea_MCSI_4violins(vortLO);
mcsarea_vMD = MCS_maxarea_MCSI_4violins(vortMD);
mcsarea_vHI = MCS_maxarea_MCSI_4violins(vortHI);
mcsarea_aLO = MCS_maxarea_MCSI_4violins(areaLO);
mcsarea_aMD = MCS_maxarea_MCSI_4violins(areaMD);
mcsarea_aHI = MCS_maxarea_MCSI_4violins(areaHI);

mcsmass_vLO = MCS_totalrainmass_MCSI_4violins(vortLO);
mcsmass_vMD = MCS_totalrainmass_MCSI_4violins(vortMD);
mcsmass_vHI = MCS_totalrainmass_MCSI_4violins(vortHI);
mcsmass_aLO = MCS_totalrainmass_MCSI_4violins(areaLO);
mcsmass_aMD = MCS_totalrainmass_MCSI_4violins(areaMD);
mcsmass_aHI = MCS_totalrainmass_MCSI_4violins(areaHI);

mcsdur_vLO = MCS_duration_4violins(vortLO);
mcsdur_vMD = MCS_duration_4violins(vortMD);
mcsdur_vHI = MCS_duration_4violins(vortHI);
mcsdur_aLO = MCS_duration_4violins(areaLO);
mcsdur_aMD = MCS_duration_4violins(areaMD);
mcsdur_aHI = MCS_duration_4violins(areaHI);

%{

%Alternatively, do for MP-MCS colloc period:
vortvar = MPVORTfullmcs_ALLYRS  ;
areavar = MPAREAfullmcs_ALLYRS  ;
% MCS_maxarea_fullmcs_4violins       ; %=  maxareapf_MCSstats_ALLYRS(:) ;
% MCS_totalrainmass_fullmcs_4violins ; %= totalrainmass_MCSstats_ALLYRSb(:)  ;
% MCS_duration_4violins              ; % = duration_MCSstats_ALLYRS  ;

mcsarea_vLO = MCS_maxarea_fullmcs_4violins(vortLO);
mcsarea_vMD = MCS_maxarea_fullmcs_4violins(vortMD);
mcsarea_vHI = MCS_maxarea_fullmcs_4violins(vortHI);
mcsarea_aLO = MCS_maxarea_fullmcs_4violins(areaLO);
mcsarea_aMD = MCS_maxarea_fullmcs_4violins(areaMD);
mcsarea_aHI = MCS_maxarea_fullmcs_4violins(areaHI);

mcsmass_vLO = MCS_totalrainmass_fullmcs_4violins(vortLO);
mcsmass_vMD = MCS_totalrainmass_fullmcs_4violins(vortMD);
mcsmass_vHI = MCS_totalrainmass_fullmcs_4violins(vortHI);
mcsmass_aLO = MCS_totalrainmass_fullmcs_4violins(areaLO);
mcsmass_aMD = MCS_totalrainmass_fullmcs_4violins(areaMD);
mcsmass_aHI = MCS_totalrainmass_fullmcs_4violins(areaHI);

mcsdur_vLO = MCS_duration_4violins(vortLO);
mcsdur_vMD = MCS_duration_4violins(vortMD);
mcsdur_vHI = MCS_duration_4violins(vortHI);
mcsdur_aLO = MCS_duration_4violins(areaLO);
mcsdur_aMD = MCS_duration_4violins(areaMD);
mcsdur_aHI = MCS_duration_4violins(areaHI);

%}







xs = 0.5;
%xf = 3.5;
xf = 2.5;
figure('position',[697,606,1098,303])

subplot(1,3,2)
ys = 5000;
yf = 200000;
exp = {'','','',''};

blahHI = mcsarea_vHI ;    
blahLO = mcsarea_vLO ;    

% kill = find(isnan(blahHI));
% blahLO(kill) = []; blahHI(kill) = [];
% kill = find(isnan(blahLO));
% blahLO(kill) = []; blahHI(kill) = [];

violin(blahHI(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahHI,25); p75 = prctile(blahHI,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)

violin(blahLO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahLO,25); p75 = prctile(blahLO,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 
%set(gca,'xtick',[0:4],'xticklabel',exp) 
% 
% [sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% [p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% if( sh == 0 & sh2 == 0 )
%     lab = 'CAPE           ';
% elseif( sh == 1 & sh2 == 0 )
%     lab = 'CAPE    KS     ';
% elseif( sh == 0 & sh2 == 1 )
%     lab = 'CAPE    R      ';
% elseif( sh == 1 & sh2 == 1 )
%     lab = 'CAPE    K-S, R ';
% end
ylabel('MCS max area')
%title([lab])
 
% %100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )
% 100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [blahMP(:);blahNO(:)],'omitnan')







subplot(1,3,1)
ys = 0; %5.0e11;
yf = 1.5e13; %2.0e13;
exp = {'','','',''};

blahHI = mcsmass_vHI ;    
blahLO = mcsmass_vLO ;    

% kill = find(isnan(blahHI));
% blahLO(kill) = []; blahHI(kill) = [];
% kill = find(isnan(blahLO));
% blahLO(kill) = []; blahHI(kill) = [];

violin(blahHI(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahHI,25); p75 = prctile(blahHI,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)

violin(blahLO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahLO,25); p75 = prctile(blahLO,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 
%set(gca,'xtick',[0:4],'xticklabel',exp) 
% 
% [sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% [p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% if( sh == 0 & sh2 == 0 )
%     lab = 'CAPE           ';
% elseif( sh == 1 & sh2 == 0 )
%     lab = 'CAPE    KS     ';
% elseif( sh == 0 & sh2 == 1 )
%     lab = 'CAPE    R      ';
% elseif( sh == 1 & sh2 == 1 )
%     lab = 'CAPE    K-S, R ';
% end
ylabel('MCS accumulated rain mass')
%title([lab])
 
% %100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )
% 100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [blahMP(:);blahNO(:)],'omitnan')






subplot(1,3,3)
ys = 6;
yf = 48;
exp = {'','','',''};

blahHI = mcsdur_vHI ;    
blahLO = mcsdur_vLO ;    

% kill = find(isnan(blahHI));
% blahLO(kill) = []; blahHI(kill) = [];
% kill = find(isnan(blahLO));
% blahLO(kill) = []; blahHI(kill) = [];

violin(blahHI(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahHI,25); p75 = prctile(blahHI,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)

violin(blahLO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahLO,25); p75 = prctile(blahLO,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 
set(gca,'ytick',[ys:6:yf]) 
%set(gca,'xtick',[0:4],'xticklabel',exp) 
% 
% [sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% [p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% if( sh == 0 & sh2 == 0 )
%     lab = 'CAPE           ';
% elseif( sh == 1 & sh2 == 0 )
%     lab = 'CAPE    KS     ';
% elseif( sh == 0 & sh2 == 1 )
%     lab = 'CAPE    R      ';
% elseif( sh == 1 & sh2 == 1 )
%     lab = 'CAPE    K-S, R ';
% end
ylabel('MCS duration ')
%title([lab])



outlab = horzcat(imout,'/Violin3RESPONSEbottomrow_MPMCSpreMCS_envstats.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);
























%%%%%%%%%%
%%%%%%%%%%  Run this after stepping thru
%%%%%%%%%%  .../PROJECTS/WACCEM/Code/VORTbpf_ENVstats_Compilation_COMMONCORE_v6.m
%%%%%%%%%%


%%%%%%%%%%
%%%%%%%%%%  Run this after stepping thru
%%%%%%%%%%  .../PROJECTS/WACCEM/Code/VORTbpf_ENVstats_Compilation_COMMONCORE_v6.m
%%%%%%%%%%


%%%%%%%%%%
%%%%%%%%%%  Run this after stepping thru
%%%%%%%%%%  .../PROJECTS/WACCEM/Code/VORTbpf_ENVstats_Compilation_COMMONCORE_v6.m
%%%%%%%%%%


%%%%%%%%%%
%%%%%%%%%%  Run this after stepping thru
%%%%%%%%%%  .../PROJECTS/WACCEM/Code/VORTbpf_ENVstats_Compilation_COMMONCORE_v6.m
%%%%%%%%%%


%%%%%%%%%%
%%%%%%%%%%  Run this after stepping thru
%%%%%%%%%%  .../PROJECTS/WACCEM/Code/VORTbpf_ENVstats_Compilation_COMMONCORE_v6.m
%%%%%%%%%%

alvl = 0.05;

vars_MP = { "MPwithMCS_maxMUCAPE_ALLYRS"; "MPwithMCS_meanMUCIN_ALLYRS"; "MPwithMCS_meanMULFC_ALLYRS"; "MPwithMCS_meanMUEL_ALLYRS"; ...
            "MPwithMCS_meanPW_ALLYRS"; "MPwithMCS_meanshearmag0to2_ALLYRS";  "MPwithMCS_meanshearmag2to9_ALLYRS"; "MPwithMCS_meanshearmag0to6_ALLYRS"; ...
            "MPwithMCS_minOMEGAsub600_ALLYRS"; "MPwithMCS_minDIVsub600_ALLYRS" };

vars_MPpreMCS = { "MPwithMCS_preMCS_maxMUCAPE_ALLYRS"; "MPwithMCS_preMCS_meanMUCIN_ALLYRS"; "MPwithMCS_preMCS_meanMULFC_ALLYRS"; "MPwithMCS_preMCS_meanMUEL_ALLYRS"; ...
            "MPwithMCS_preMCS_meanPW_ALLYRS"; "MPwithMCS_preMCS_meanshearmag0to2_ALLYRS";  "MPwithMCS_preMCS_meanshearmag2to9_ALLYRS"; "MPwithMCS_preMCS_meanshearmag0to6_ALLYRS"; ...
            "MPwithMCS_preMCS_minOMEGAsub600_ALLYRS"; "MPwithMCS_preMCS_minDIVsub600_ALLYRS" };

vars_NO = { "MPwithoutMCS_maxMUCAPE_ALLYRS"; "MPwithoutMCS_meanMUCIN_ALLYRS"; "MPwithoutMCS_meanMULFC_ALLYRS"; "MPwithoutMCS_meanMUEL_ALLYRS"; ...
            "MPwithoutMCS_meanPW_ALLYRS"; "MPwithoutMCS_meanshearmag0to2_ALLYRS";  "MPwithoutMCS_meanshearmag2to9_ALLYRS"; "MPwithoutMCS_meanshearmag0to6_ALLYRS"; ...
            "MPwithoutMCS_minOMEGAsub600_ALLYRS"; "MPwithoutMCS_minDIVsub600_ALLYRS" };

xs = 0.5;
xf = 2.5;
figure('position',[188,172,1278,661])

subplot(2,5,1)
ys = 0;
yf = 6000;
%exp = {'','MPs with MCSI','MPs without MCSI',''};
exp = {'','','',''};
clear blahNO blahMP
%blahMP = eval(string(vars_MP(1,:))); blahMP(isnan(blahMP)) = [];
blahMP = eval(string(vars_MPpreMCS(1,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blahNO = eval(string(vars_NO(1,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp) 

[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = 'CAPE           ';
elseif( sh == 1 & sh2 == 0 )
    lab = 'CAPE    KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = 'CAPE    R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = 'CAPE    K-S, R ';
end
ylabel('[J/kg]')
title([lab])

%100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )
100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [blahMP(:);blahNO(:)],'omitnan')

subplot(2,5,2)
ys = -200;
yf = 0;
%exp = {'','MPs with MCSI','MPs without MCSI',''};
exp = {'','','',''};
clear blahNO blahMP
%blahMP = eval(string(vars_MP(2,:))); blahMP(isnan(blahMP)) = [];
blahMP = eval(string(vars_MPpreMCS(2,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blahNO = eval(string(vars_NO(2,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp) 
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = 'CIN           ';
elseif( sh == 1 & sh2 == 0 )
    lab = 'CIN    KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = 'CIN    R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = 'CIN    K-S, R ';
end
ylabel('[J/kg]')
title([lab])

100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )


subplot(2,5,3)
ys = 500/1000;
yf = 5500/1000;
exp = {'','','',''};
clear blahNO blahMP
%blahMP = eval(string(vars_MP(3,:)))/1000; blahMP(isnan(blahMP)) = [];
blahMP = eval(string(vars_MPpreMCS(3,:)))/1000; blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blahNO = eval(string(vars_NO(3,:)))/1000; blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp) 
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = 'LFC           ';
elseif( sh == 1 & sh2 == 0 )
    lab = 'LFC    KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = 'LFC    R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = 'LFC    K-S, R ';
end
ylabel('[km]')
title([lab])


100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )




% subplot(2,5,4)
% ys = 4000/1000;
% yf = 15000/1000;
% clear blahNO blahMP
% exp = {'','','',''};
% blahMP = eval(string(vars_MP(4,:)))/1000; blahMP(isnan(blahMP)) = [];
% violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
% hold on
% p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
% plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
% blahNO = eval(string(vars_NO(4,:)))/1000; blahNO(isnan(blahNO)) = [];
% violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
% axis([xs xf ys yf])
% set(gca,'xtick',[0:3],'xticklabel',exp) 
% [sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% [p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% if( sh == 0 & sh2 == 0 )
%     lab = 'EL           ';
% elseif( sh == 1 & sh2 == 0 )
%     lab = 'EL    KS     ';
% elseif( sh == 0 & sh2 == 1 )
%     lab = 'EL    R      ';
% elseif( sh == 1 & sh2 == 1 )
%     lab = 'EL    K-S, R ';
% end
% title([lab])
% ylabel('[km]')
% yticks([4000:1500:16000]/1000)
% set(gca,'xtick',[0:3],'xticklabel',exp) 
% 
% 100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )



subplot(2,5,4)
ys = 0.02*1000;
yf = 0.065*1000;
clear blahNO blahMP
exp = {'','','',''};
%blahMP = eval(string(vars_MP(5,:))); blahMP(isnan(blahMP)) = [];
blahMP = eval(string(vars_MPpreMCS(5,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blahNO = eval(string(vars_NO(5,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp) 
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = 'PW           ';
elseif( sh == 1 & sh2 == 0 )
    lab = 'PW    KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = 'PW    R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = 'PW    K-S, R ';
end
title([lab])
ylabel('[mm]')
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp) 



100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )



subplot(2,5,5)
ys = -8;
yf = +0.5;
exp = {'','','',''};
clear blahNO blahMP
%blahMP = eval(string(vars_MP(9,:))); blahMP(isnan(blahMP)) = [];
blahMP = eval(string(vars_MPpreMCS(9,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blahNO = eval(string(vars_NO(9,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp) 
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = 'Omega          ';
elseif( sh == 1 & sh2 == 0 )
    lab = 'Omega   KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = 'Omega   R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = 'Omega   K-S, R ';
end
title([lab])
ylabel('[Pa/s]')
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp) 

100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )



subplot(2,5,6)
ys = -0.0006;
yf = +0.0;
clear blahNO blahMP
exp = {'','','',''};
%blahMP = eval(string(vars_MP(10,:))); blahMP(isnan(blahMP)) = [];
blahMP = eval(string(vars_MPpreMCS(10,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blahNO = eval(string(vars_NO(10,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp) 
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = 'Div          ';
elseif( sh == 1 & sh2 == 0 )
    lab = 'Div   KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = 'Div   R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = 'Div   K-S, R ';
end
title([lab])
ylabel('[1/s]')
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp) 

100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )




subplot(2,5,7)
ys = 0.0;
yf = 20;
clear blahNO blahMP
exp = {'','','',''};
%blahMP = eval(string(vars_MP(6,:))); blahMP(isnan(blahMP)) = [];
blahMP = eval(string(vars_MPpreMCS(6,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blahNO = eval(string(vars_NO(6,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp) 
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = '0-2 Shear          ';
elseif( sh == 1 & sh2 == 0 )
    lab = '0-2 Shear   KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = '0-2 Shear   R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = '0-2 Shear   K-S, R ';
end
title([lab])
ylabel('[m/s]')
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp) 





subplot(2,5,8)
ys = 0.0;
yf = 40;
clear blahNO blahMP
exp = {'','','',''};
%blahMP = eval(string(vars_MP(7,:))); blahMP(isnan(blahMP)) = [];
blahMP = eval(string(vars_MPpreMCS(7,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blahNO = eval(string(vars_NO(7,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp) 
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = '2-9 Shear          ';
elseif( sh == 1 & sh2 == 0 )
    lab = '2-9 Shear   KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = '2-9 Shear   R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = '2-9 Shear   K-S, R ';
end
title([lab])
ylabel('[m/s]')
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp) 




subplot(2,5,9)
ys = 0.0;
yf = 30;
exp = {'','','',''};
clear blahNO blahMP
blahMP = eval(string(vars_MP(8,:))); blahMP(isnan(blahMP)) = [];
%blahMP = eval(string(vars_MPpreMCS(8,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
blahNO = eval(string(vars_NO(8,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp) 
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = '0-6 Shear          ';
elseif( sh == 1 & sh2 == 0 )
    lab = '0-6 Shear   KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = '0-6 Shear   R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = '0-6 Shear   K-S, R ';
end
title([lab])
ylabel('[m/s]')
axis([xs xf ys yf])
set(gca,'xtick',[0:3],'xticklabel',exp) 



outlab = horzcat(imout,'/Violin3_MPMCS_envstats',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);






%%%%%%%%%%
%%%%%%%%%%  Run this after stepping thru
%%%%%%%%%%  .../PROJECTS/WACCEM/Code/VORTbpf_ENVstats_Compilation_COMMONCORE_v6.m
%%%%%%%%%%

alvl = 0.05;

vars_MP = { "MPwithMCS_maxMUCAPE_ALLYRS"; "MPwithMCS_meanMUCIN_ALLYRS"; "MPwithMCS_meanMULFC_ALLYRS"; "MPwithMCS_meanMUEL_ALLYRS"; ...
            "MPwithMCS_meanPW_ALLYRS"; "MPwithMCS_meanshearmag0to2_ALLYRS";  "MPwithMCS_meanshearmag2to9_ALLYRS"; "MPwithMCS_meanshearmag0to6_ALLYRS"; ...
            "MPwithMCS_minOMEGAsub600_ALLYRS"; "MPwithMCS_minDIVsub600_ALLYRS" };

vars_MPpreMCS = { "MPwithMCS_preMCS_maxMUCAPE_ALLYRS"; "MPwithMCS_preMCS_meanMUCIN_ALLYRS"; "MPwithMCS_preMCS_meanMULFC_ALLYRS"; "MPwithMCS_preMCS_meanMUEL_ALLYRS"; ...
            "MPwithMCS_preMCS_meanPW_ALLYRS"; "MPwithMCS_preMCS_meanshearmag0to2_ALLYRS";  "MPwithMCS_preMCS_meanshearmag2to9_ALLYRS"; "MPwithMCS_preMCS_meanshearmag0to6_ALLYRS"; ...
            "MPwithMCS_preMCS_minOMEGAsub600_ALLYRS"; "MPwithMCS_preMCS_minDIVsub600_ALLYRS" };

vars_NO = { "MPwithoutMCS_maxMUCAPE_ALLYRS"; "MPwithoutMCS_meanMUCIN_ALLYRS"; "MPwithoutMCS_meanMULFC_ALLYRS"; "MPwithoutMCS_meanMUEL_ALLYRS"; ...
            "MPwithoutMCS_meanPW_ALLYRS"; "MPwithoutMCS_meanshearmag0to2_ALLYRS";  "MPwithoutMCS_meanshearmag2to9_ALLYRS"; "MPwithoutMCS_meanshearmag0to6_ALLYRS"; ...
            "MPwithoutMCS_minOMEGAsub600_ALLYRS"; "MPwithoutMCS_minDIVsub600_ALLYRS" };

xs = 0.5;
xf = 3.5;
%xf = 2.5;
figure('position',[188,172,1278,661])

subplot(2,5,1)
ys = 0;
yf = 6000;
%exp = {'','MPs with MCSI','MPs without MCSI',''};
exp = {'','','',''};
clear blahNO blahMP

blahMP = eval(string(vars_MP(1,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)

blahMP = eval(string(vars_MPpreMCS(1,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[2 0 0 5],'facecolor',[0.7 0.0 0])
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

blahNO = eval(string(vars_NO(1,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)

% blahNO = eval(string(vars_NO(1,:))); blahNO(isnan(blahNO)) = [];
% violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

axis([xs xf ys yf])
%set(gca,'xtick',[0:3],'xticklabel',exp) 
set(gca,'xtick',[0:4],'xticklabel',exp) 

[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = 'CAPE           ';
elseif( sh == 1 & sh2 == 0 )
    lab = 'CAPE    KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = 'CAPE    R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = 'CAPE    K-S, R ';
end
ylabel('[J/kg]')
title([lab])

%100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )
100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [blahMP(:);blahNO(:)],'omitnan')





subplot(2,5,2)
ys = -200;
yf = 0;
%exp = {'','MPs with MCSI','MPs without MCSI',''};
exp = {'','','',''};
clear blahNO blahMP

blahMP = eval(string(vars_MP(2,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)

blahMP = eval(string(vars_MPpreMCS(2,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[2 0 0 5],'facecolor',[0.7 0.0 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

blahNO = eval(string(vars_NO(2,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)

% blahNO = eval(string(vars_NO(2,:))); blahNO(isnan(blahNO)) = [];
% violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 
%set(gca,'xtick',[0:3],'xticklabel',exp) 
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = 'CIN           ';
elseif( sh == 1 & sh2 == 0 )
    lab = 'CIN    KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = 'CIN    R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = 'CIN    K-S, R ';
end
ylabel('[J/kg]')
title([lab])

100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )


subplot(2,5,3)
ys = 500/1000;
yf = 5500/1000;
exp = {'','','',''};
clear blahNO blahMP

blahMP = eval(string(vars_MP(3,:)))/1000; blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)

blahMP = eval(string(vars_MPpreMCS(3,:)))/1000; blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[2 0 0 5],'facecolor',[0.7 0.0 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

blahNO = eval(string(vars_NO(3,:)))/1000; blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)

% blahNO = eval(string(vars_NO(3,:)))/1000; blahNO(isnan(blahNO)) = [];
% violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 
%set(gca,'xtick',[0:3],'xticklabel',exp)
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = 'LFC           ';
elseif( sh == 1 & sh2 == 0 )
    lab = 'LFC    KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = 'LFC    R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = 'LFC    K-S, R ';
end
ylabel('[km]')
title([lab])


100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )




% subplot(2,5,4)
% ys = 4000/1000;
% yf = 15000/1000;
% clear blahNO blahMP
% exp = {'','','',''};
% blahMP = eval(string(vars_MP(4,:)))/1000; blahMP(isnan(blahMP)) = [];
% violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
% hold on
% p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
% plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
% blahNO = eval(string(vars_NO(4,:)))/1000; blahNO(isnan(blahNO)) = [];
% violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
% axis([xs xf ys yf])
% set(gca,'xtick',[0:3],'xticklabel',exp) 
% [sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% [p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% if( sh == 0 & sh2 == 0 )
%     lab = 'EL           ';
% elseif( sh == 1 & sh2 == 0 )
%     lab = 'EL    KS     ';
% elseif( sh == 0 & sh2 == 1 )
%     lab = 'EL    R      ';
% elseif( sh == 1 & sh2 == 1 )
%     lab = 'EL    K-S, R ';
% end
% title([lab])
% ylabel('[km]')
% yticks([4000:1500:16000]/1000)
% set(gca,'xtick',[0:3],'xticklabel',exp) 
% 
% 100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )



subplot(2,5,4)
ys = 0.02*1000;
yf = 0.065*1000;
clear blahNO blahMP
exp = {'','','',''};

blahMP = eval(string(vars_MP(5,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)

blahMP = eval(string(vars_MPpreMCS(5,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[2 0 0 5],'facecolor',[0.7 0.0 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

blahNO = eval(string(vars_NO(5,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)

% blahNO = eval(string(vars_NO(5,:))); blahNO(isnan(blahNO)) = [];
% violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

axis([xs xf ys yf])
%set(gca,'xtick',[0:3],'xticklabel',exp) 
set(gca,'xtick',[0:4],'xticklabel',exp) 
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = 'PW           ';
elseif( sh == 1 & sh2 == 0 )
    lab = 'PW    KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = 'PW    R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = 'PW    K-S, R ';
end
title([lab])
ylabel('[mm]')
axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 



100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )



subplot(2,5,5)
ys = -8;
yf = +0.5;
exp = {'','','',''};
clear blahNO blahMP

blahMP = eval(string(vars_MP(9,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)

blahMP = eval(string(vars_MPpreMCS(9,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[2 0 0 5],'facecolor',[0.7 0.0 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

blahNO = eval(string(vars_NO(9,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)

% blahNO = eval(string(vars_NO(9,:))); blahNO(isnan(blahNO)) = [];
% violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 
%set(gca,'xtick',[0:3],'xticklabel',exp) 
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = 'Omega          ';
elseif( sh == 1 & sh2 == 0 )
    lab = 'Omega   KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = 'Omega   R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = 'Omega   K-S, R ';
end
title([lab])
ylabel('[Pa/s]')
axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 

100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )



subplot(2,5,6)
ys = -0.0006;
yf = +0.0;
clear blahNO blahMP
exp = {'','','',''};

blahMP = eval(string(vars_MP(10,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)

blahMP = eval(string(vars_MPpreMCS(10,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[2 0 0 5],'facecolor',[0.7 0.0 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

blahNO = eval(string(vars_NO(10,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)

% blahNO = eval(string(vars_NO(10,:))); blahNO(isnan(blahNO)) = [];
% violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 
%set(gca,'xtick',[0:3],'xticklabel',exp) 
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = 'Div          ';
elseif( sh == 1 & sh2 == 0 )
    lab = 'Div   KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = 'Div   R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = 'Div   K-S, R ';
end
title([lab])
ylabel('[1/s]')
axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 

100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )




subplot(2,5,7)
ys = 0.0;
yf = 20;
clear blahNO blahMP
exp = {'','','',''};

blahMP = eval(string(vars_MP(6,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)

blahMP = eval(string(vars_MPpreMCS(6,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[2 0 0 5],'facecolor',[0.7 0.0 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

blahNO = eval(string(vars_NO(6,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)

% blahNO = eval(string(vars_NO(6,:))); blahNO(isnan(blahNO)) = [];
% violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 
%set(gca,'xtick',[0:3],'xticklabel',exp) 
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = '0-2 Shear          ';
elseif( sh == 1 & sh2 == 0 )
    lab = '0-2 Shear   KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = '0-2 Shear   R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = '0-2 Shear   K-S, R ';
end
title([lab])
ylabel('[m/s]')
axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 





subplot(2,5,8)
ys = 0.0;
yf = 40;
clear blahNO blahMP
exp = {'','','',''};

blahMP = eval(string(vars_MP(7,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)

blahMP = eval(string(vars_MPpreMCS(7,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[2 0 0 5],'facecolor',[0.7 0.0 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

blahNO = eval(string(vars_NO(7,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)

% blahNO = eval(string(vars_NO(7,:))); blahNO(isnan(blahNO)) = [];
% violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 
%set(gca,'xtick',[0:3],'xticklabel',exp) 
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = '2-9 Shear          ';
elseif( sh == 1 & sh2 == 0 )
    lab = '2-9 Shear   KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = '2-9 Shear   R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = '2-9 Shear   K-S, R ';
end
title([lab])
ylabel('[m/s]')
axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 




subplot(2,5,9)
ys = 0.0;
yf = 30;
exp = {'','','',''};
clear blahNO blahMP

blahMP = eval(string(vars_MP(8,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)

blahMP = eval(string(vars_MPpreMCS(8,:))); blahMP(isnan(blahMP)) = [];
violin(blahMP(:),'x',[2 0 0 5],'facecolor',[0.7 0.0 0])
hold on
p25 = prctile(blahMP,25); p75 = prctile(blahMP,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

blahNO = eval(string(vars_NO(8,:))); blahNO(isnan(blahNO)) = [];
violin(blahNO(:),'x',[3 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
plot(3,p25,'*k','MarkerSize',5); plot(3,p75,'*k','MarkerSize',5)

% blahNO = eval(string(vars_NO(8,:))); blahNO(isnan(blahNO)) = [];
% violin(blahNO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahNO,25); p75 = prctile(blahNO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 
%set(gca,'xtick',[0:3],'xticklabel',exp) 
[sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
[p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
if( sh == 0 & sh2 == 0 )
    lab = '0-6 Shear          ';
elseif( sh == 1 & sh2 == 0 )
    lab = '0-6 Shear   KS     ';
elseif( sh == 0 & sh2 == 1 )
    lab = '0-6 Shear   R      ';
elseif( sh == 1 & sh2 == 1 )
    lab = '0-6 Shear   K-S, R ';
end
title([lab])
ylabel('[m/s]')
axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 


% 
% outlab = horzcat(imout,'/Violin3_MPMCSpreMCS_envstats',keptmonslab,'.eps');
% EPSprint = horzcat('print -painters -depsc ',outlab);
% eval([EPSprint]);

outlab = horzcat(imout,'/Violin3RESPONSE_MPMCSpreMCS_envstats.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);



%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment    bonus fig
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment   break up env metrics into +/- 33 percitles
%%%%%%%%%                      of MP vorticity and area
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment
%%%%%%%%% reviewer 3 comment


alvl = 0.05;

% vort66 = prctile(maxVOR600_MPstats_ALLYRS(:),66)
% vort33 = prctile(maxVOR600_MPstats_ALLYRS(:),33)
% area66 = prctile(area_MPstats_ALLYRS(:),66)
% area33 = prctile(area_MPstats_ALLYRS(:),33)
% 
% vortLO = find( maxVOR600_MPstats_ALLYRS <= vort33 );
% vortMD = find( maxVOR600_MPstats_ALLYRS > vort33  &   maxVOR600_MPstats_ALLYRS <= vort66   );
% vortHI = find( maxVOR600_MPstats_ALLYRS > vort66 );
% 
% areaLO = find( area_MPstats_ALLYRS <= area33 );
% areaMD = find( area_MPstats_ALLYRS > area33  &   area_MPstats_ALLYRS <= area66   );
% areaHI = find( area_MPstats_ALLYRS > area66 );

vortvar = permute( max(maxVOR600_MPstats_ALLYRS,[],1),[2 3 1])  ;
areavar = permute( max(area_MPstats_ALLYRS,[],1),[2 3 1])  ;

vort66 = prctile(vortvar(:),66)
vort33 = prctile(vortvar(:),33)
area66 = prctile(areavar(:),66)
area33 = prctile(areavar(:),33)

vortLO = find( vortvar <= vort33 );
vortMD = find( vortvar > vort33  &   vortvar <= vort66   );
vortHI = find( vortvar > vort66 );

areaLO = find( areavar <= area33 );
areaMD = find( areavar > area33  &   areavar <= area66   );
areaHI = find( areavar > area66 );


% vars_MP = { "MPwithMCS_maxMUCAPE_ALLYRS"; "MPwithMCS_meanMUCIN_ALLYRS"; "MPwithMCS_meanMULFC_ALLYRS"; "MPwithMCS_meanMUEL_ALLYRS"; ...
%             "MPwithMCS_meanPW_ALLYRS"; "MPwithMCS_meanshearmag0to2_ALLYRS";  "MPwithMCS_meanshearmag2to9_ALLYRS"; "MPwithMCS_meanshearmag0to6_ALLYRS"; ...
%             "MPwithMCS_minOMEGAsub600_ALLYRS"; "MPwithMCS_minDIVsub600_ALLYRS" };

shear06_vLO = MPwithMCS_meanshearmag0to6_ALLYRS(vortLO);
shear06_vMD = MPwithMCS_meanshearmag0to6_ALLYRS(vortMD);
shear06_vHI = MPwithMCS_meanshearmag0to6_ALLYRS(vortHI);
shear06_aLO = MPwithMCS_meanshearmag0to6_ALLYRS(areaLO);
shear06_aMD = MPwithMCS_meanshearmag0to6_ALLYRS(areaMD);
shear06_aHI = MPwithMCS_meanshearmag0to6_ALLYRS(areaHI);

omega_vLO = MPwithMCS_minOMEGAsub600_ALLYRS(vortLO);
omega_vMD = MPwithMCS_minOMEGAsub600_ALLYRS(vortMD);
omega_vHI = MPwithMCS_minOMEGAsub600_ALLYRS(vortHI);
omega_aLO = MPwithMCS_minOMEGAsub600_ALLYRS(areaLO);
omega_aMD = MPwithMCS_minOMEGAsub600_ALLYRS(areaMD);
omega_aHI = MPwithMCS_minOMEGAsub600_ALLYRS(areaHI);

pw_vLO = MPwithMCS_meanPW_ALLYRS(vortLO);
pw_vMD = MPwithMCS_meanPW_ALLYRS(vortMD);
pw_vHI = MPwithMCS_meanPW_ALLYRS(vortHI);
pw_aLO = MPwithMCS_meanPW_ALLYRS(areaLO);
pw_aMD = MPwithMCS_meanPW_ALLYRS(areaMD);
pw_aHI = MPwithMCS_meanPW_ALLYRS(areaHI);

cape_vLO = MPwithMCS_maxMUCAPE_ALLYRS(vortLO);
cape_vMD = MPwithMCS_maxMUCAPE_ALLYRS(vortMD);
cape_vHI = MPwithMCS_maxMUCAPE_ALLYRS(vortHI);
cape_aLO = MPwithMCS_maxMUCAPE_ALLYRS(areaLO);
cape_aMD = MPwithMCS_maxMUCAPE_ALLYRS(areaMD);
cape_aHI = MPwithMCS_maxMUCAPE_ALLYRS(areaHI);


cin_vLO = MPwithMCS_meanMUCIN_ALLYRS(vortLO);
cin_vMD = MPwithMCS_meanMUCIN_ALLYRS(vortMD);
cin_vHI = MPwithMCS_meanMUCIN_ALLYRS(vortHI);
cin_aLO = MPwithMCS_meanMUCIN_ALLYRS(areaLO);
cin_aMD = MPwithMCS_meanMUCIN_ALLYRS(areaMD);
cin_aHI = MPwithMCS_meanMUCIN_ALLYRS(areaHI);


xs = 0.5;
%xf = 3.5;
xf = 2.5;
figure('position',[697,606,1098,303])

subplot(1,3,2)
ys = 24;
yf = 70;
exp = {'','','',''};

blahHI = pw_vHI ;    
blahLO = pw_vLO ;    

% kill = find(isnan(blahHI));
% blahLO(kill) = []; blahHI(kill) = [];
% kill = find(isnan(blahLO));
% blahLO(kill) = []; blahHI(kill) = [];

violin(blahHI(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahHI,25); p75 = prctile(blahHI,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)

violin(blahLO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahLO,25); p75 = prctile(blahLO,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 
%set(gca,'xtick',[0:4],'xticklabel',exp) 
% 
% [sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% [p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% if( sh == 0 & sh2 == 0 )
%     lab = 'CAPE           ';
% elseif( sh == 1 & sh2 == 0 )
%     lab = 'CAPE    KS     ';
% elseif( sh == 0 & sh2 == 1 )
%     lab = 'CAPE    R      ';
% elseif( sh == 1 & sh2 == 1 )
%     lab = 'CAPE    K-S, R ';
% end
ylabel('PW')
%title([lab])
 
% %100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )
% 100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [blahMP(:);blahNO(:)],'omitnan')







subplot(1,3,3)
ys = 0;
yf = 6000;
exp = {'','','',''};

blahHI = cape_vHI ;    
blahLO = cape_vLO ;    

% kill = find(isnan(blahHI));
% blahLO(kill) = []; blahHI(kill) = [];
% kill = find(isnan(blahLO));
% blahLO(kill) = []; blahHI(kill) = [];

violin(blahHI(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahHI,25); p75 = prctile(blahHI,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)

violin(blahLO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahLO,25); p75 = prctile(blahLO,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 
%set(gca,'xtick',[0:4],'xticklabel',exp) 
% 
% [sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% [p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% if( sh == 0 & sh2 == 0 )
%     lab = 'CAPE           ';
% elseif( sh == 1 & sh2 == 0 )
%     lab = 'CAPE    KS     ';
% elseif( sh == 0 & sh2 == 1 )
%     lab = 'CAPE    R      ';
% elseif( sh == 1 & sh2 == 1 )
%     lab = 'CAPE    K-S, R ';
% end
ylabel('CAPE')
%title([lab])
 
% %100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )
% 100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [blahMP(:);blahNO(:)],'omitnan')






subplot(1,3,1)
ys = -7;
yf = 0;
exp = {'','','',''};

blahHI = omega_vHI ;    
blahLO = omega_vLO ;    

% kill = find(isnan(blahHI));
% blahLO(kill) = []; blahHI(kill) = [];
% kill = find(isnan(blahLO));
% blahLO(kill) = []; blahHI(kill) = [];

violin(blahHI(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
hold on
p25 = prctile(blahHI,25); p75 = prctile(blahHI,75);
plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)

violin(blahLO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
p25 = prctile(blahLO,25); p75 = prctile(blahLO,75);
plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)

axis([xs xf ys yf])
set(gca,'xtick',[0:4],'xticklabel',exp) 
%set(gca,'xtick',[0:4],'xticklabel',exp) 
% 
% [sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% [p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% if( sh == 0 & sh2 == 0 )
%     lab = 'CAPE           ';
% elseif( sh == 1 & sh2 == 0 )
%     lab = 'CAPE    KS     ';
% elseif( sh == 0 & sh2 == 1 )
%     lab = 'CAPE    R      ';
% elseif( sh == 1 & sh2 == 1 )
%     lab = 'CAPE    K-S, R ';
% end
ylabel('Omega')
%title([lab])
 
% %100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )
% 100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [blahMP(:);blahNO(:)],'omitnan')









% subplot(1,5,4)
% ys = 0;
% yf = 30;
% exp = {'','','',''};
% 
% blahHI = shear06_vHI ;    
% blahLO = shear06_vLO ;    
% 
% % kill = find(isnan(blahHI));
% % blahLO(kill) = []; blahHI(kill) = [];
% % kill = find(isnan(blahLO));
% % blahLO(kill) = []; blahHI(kill) = [];
% 
% violin(blahHI(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
% hold on
% p25 = prctile(blahHI,25); p75 = prctile(blahHI,75);
% plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
% 
% violin(blahLO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahLO,25); p75 = prctile(blahLO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
% 
% axis([xs xf ys yf])
% set(gca,'xtick',[0:4],'xticklabel',exp) 
% %set(gca,'xtick',[0:4],'xticklabel',exp) 
% % 
% % [sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% % [p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% % if( sh == 0 & sh2 == 0 )
% %     lab = 'CAPE           ';
% % elseif( sh == 1 & sh2 == 0 )
% %     lab = 'CAPE    KS     ';
% % elseif( sh == 0 & sh2 == 1 )
% %     lab = 'CAPE    R      ';
% % elseif( sh == 1 & sh2 == 1 )
% %     lab = 'CAPE    K-S, R ';
% % end
% ylabel('0-6 km shear')
% %title([lab])
%  
% % %100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )
% % 100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [blahMP(:);blahNO(:)],'omitnan')



% subplot(1,4,2)
% ys = -200;
% yf = 0;
% exp = {'','','',''};
% 
% blahHI = cin_vHI ;    
% blahLO = cin_vLO ;    
% 
% % kill = find(isnan(blahHI));
% % blahLO(kill) = []; blahHI(kill) = [];
% % kill = find(isnan(blahLO));
% % blahLO(kill) = []; blahHI(kill) = [];
% 
% violin(blahHI(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
% hold on
% p25 = prctile(blahHI,25); p75 = prctile(blahHI,75);
% plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
% 
% violin(blahLO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahLO,25); p75 = prctile(blahLO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
% 
% axis([xs xf ys yf])
% set(gca,'xtick',[0:4],'xticklabel',exp) 
% %set(gca,'xtick',[0:4],'xticklabel',exp) 
% % 
% % [sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% % [p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% % if( sh == 0 & sh2 == 0 )
% %     lab = 'CAPE           ';
% % elseif( sh == 1 & sh2 == 0 )
% %     lab = 'CAPE    KS     ';
% % elseif( sh == 0 & sh2 == 1 )
% %     lab = 'CAPE    R      ';
% % elseif( sh == 1 & sh2 == 1 )
% %     lab = 'CAPE    K-S, R ';
% % end
% ylabel('cin')
% %title([lab])
 
% %100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )
% 100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [blahMP(:);blahNO(:)],'omitnan')

outlab = horzcat(imout,'/Rev3_violins.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);





% subplot(2,4,5)
% ys = 24;
% yf = 60;
% exp = {'','','',''};
% 
% blahHI = pw_aLO ;    
% blahLO = pw_aHI ;    
% 
% % kill = find(isnan(blahHI));
% % blahLO(kill) = []; blahHI(kill) = [];
% % kill = find(isnan(blahLO));
% % blahLO(kill) = []; blahHI(kill) = [];
% 
% violin(blahHI(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
% hold on
% p25 = prctile(blahHI,25); p75 = prctile(blahHI,75);
% plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
% 
% violin(blahLO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahLO,25); p75 = prctile(blahLO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
% 
% axis([xs xf ys yf])
% set(gca,'xtick',[0:4],'xticklabel',exp) 
% %set(gca,'xtick',[0:4],'xticklabel',exp) 
% % 
% % [sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% % [p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% % if( sh == 0 & sh2 == 0 )
% %     lab = 'CAPE           ';
% % elseif( sh == 1 & sh2 == 0 )
% %     lab = 'CAPE    KS     ';
% % elseif( sh == 0 & sh2 == 1 )
% %     lab = 'CAPE    R      ';
% % elseif( sh == 1 & sh2 == 1 )
% %     lab = 'CAPE    K-S, R ';
% % end
% ylabel('PW')
% %title([lab])
%  
% % %100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )
% % 100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [blahMP(:);blahNO(:)],'omitnan')
% 
% 
% 
% 
% subplot(2,4,6)
% ys = 0;
% yf = 6000;
% exp = {'','','',''};
% 
% blahHI = cape_aLO ;    
% blahLO = cape_aHI ;    
% 
% % kill = find(isnan(blahHI));
% % blahLO(kill) = []; blahHI(kill) = [];
% % kill = find(isnan(blahLO));
% % blahLO(kill) = []; blahHI(kill) = [];
% 
% violin(blahHI(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
% hold on
% p25 = prctile(blahHI,25); p75 = prctile(blahHI,75);
% plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
% 
% violin(blahLO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahLO,25); p75 = prctile(blahLO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
% 
% axis([xs xf ys yf])
% set(gca,'xtick',[0:4],'xticklabel',exp) 
% %set(gca,'xtick',[0:4],'xticklabel',exp) 
% % 
% % [sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% % [p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% % if( sh == 0 & sh2 == 0 )
% %     lab = 'CAPE           ';
% % elseif( sh == 1 & sh2 == 0 )
% %     lab = 'CAPE    KS     ';
% % elseif( sh == 0 & sh2 == 1 )
% %     lab = 'CAPE    R      ';
% % elseif( sh == 1 & sh2 == 1 )
% %     lab = 'CAPE    K-S, R ';
% % end
% ylabel('CAPE')
% %title([lab])
%  
% % %100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )
% % 100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [blahMP(:);blahNO(:)],'omitnan')
% 
% 
% 
% 
% subplot(2,4,7)
% ys = -5;
% yf = 0;
% exp = {'','','',''};
% 
% blahHI = omega_aLO ;    
% blahLO = omega_aHI ;    
% 
% % kill = find(isnan(blahHI));
% % blahLO(kill) = []; blahHI(kill) = [];
% % kill = find(isnan(blahLO));
% % blahLO(kill) = []; blahHI(kill) = [];
% 
% violin(blahHI(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
% hold on
% p25 = prctile(blahHI,25); p75 = prctile(blahHI,75);
% plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
% 
% violin(blahLO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahLO,25); p75 = prctile(blahLO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
% 
% axis([xs xf ys yf])
% set(gca,'xtick',[0:4],'xticklabel',exp) 
% %set(gca,'xtick',[0:4],'xticklabel',exp) 
% % 
% % [sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% % [p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% % if( sh == 0 & sh2 == 0 )
% %     lab = 'CAPE           ';
% % elseif( sh == 1 & sh2 == 0 )
% %     lab = 'CAPE    KS     ';
% % elseif( sh == 0 & sh2 == 1 )
% %     lab = 'CAPE    R      ';
% % elseif( sh == 1 & sh2 == 1 )
% %     lab = 'CAPE    K-S, R ';
% % end
% ylabel('Omega')
% %title([lab])
%  
% % %100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )
% % 100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [blahMP(:);blahNO(:)],'omitnan')
% 
% 
% 
% 
% 
% subplot(2,4,8)
% ys = 0;
% yf = 30;
% exp = {'','','',''};
% 
% blahHI = shear06_aLO ;    
% blahLO = shear06_aHI ;    
% 
% % kill = find(isnan(blahHI));
% % blahLO(kill) = []; blahHI(kill) = [];
% % kill = find(isnan(blahLO));
% % blahLO(kill) = []; blahHI(kill) = [];
% 
% violin(blahHI(:),'x',[1 0 0 5],'facecolor',[1 0.5 0])
% hold on
% p25 = prctile(blahHI,25); p75 = prctile(blahHI,75);
% plot(1,p25,'*k','MarkerSize',5); plot(1,p75,'*k','MarkerSize',5)
% 
% violin(blahLO(:),'x',[2 0 0 5],'facecolor',[0 0.3 1])
% p25 = prctile(blahLO,25); p75 = prctile(blahLO,75);
% plot(2,p25,'*k','MarkerSize',5); plot(2,p75,'*k','MarkerSize',5)
% 
% axis([xs xf ys yf])
% set(gca,'xtick',[0:4],'xticklabel',exp) 
% %set(gca,'xtick',[0:4],'xticklabel',exp) 
% % 
% % [sh,p]   = kstest2( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% % [p2,sh2] = ranksum( blahMP(:), blahNO(:), 'Alpha', alvl ) ;
% % if( sh == 0 & sh2 == 0 )
% %     lab = 'CAPE           ';
% % elseif( sh == 1 & sh2 == 0 )
% %     lab = 'CAPE    KS     ';
% % elseif( sh == 0 & sh2 == 1 )
% %     lab = 'CAPE    R      ';
% % elseif( sh == 1 & sh2 == 1 )
% %     lab = 'CAPE    K-S, R ';
% % end
% ylabel('0-6 km shear')
% %title([lab])
%  
% % %100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [mean(blahMP(:),'omitnan'), mean(blahNO(:),'omitnan')] )
% % 100*(mean(blahNO(:),'omitnan') - mean(blahMP(:),'omitnan'))  /  mean( [blahMP(:);blahNO(:)],'omitnan')

