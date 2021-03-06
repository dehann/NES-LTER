%cellbatch5_field created from cellbatch4_field for MVCO data, corrected
%logic error in pe separation of Syn, junk, cryto (junkind with OR not
%AND), April 2007 Heidi
%cellbatch4_field created from cellbatch3_field for MVCO May 2003 data (new
%PE separation since signals for large euks are above baseline), 5/11/03 Heidi
%cellbatch3_field created from cellbatch3 to handle single sample syringe port (6)
%cellbatch3 created from cellbatch2_labalt, for new file format, 3/03 Heidi
%cellbatch2 for MVCO, modified from cellbatch.m to add simple euk junk
%discrimination and simple crypto separations
%created from cellproc, separate with and without pe, no clustering (for micro&8018 exp't) heidi 1/10/02
%no bead match yet since no beads in data

%process for cells
%heiditemp4 - separate with and without pe, then cluster

%timeinterval = 3600;  %sec (3600 = 1 hr), resolution for final values

timeinterval = 1/24;

if year2do <= 2004,
    mergedtitles = {'rec number' 'PE' 'FLS' 'CHL' 'SSC' 'CHLpk' 'Class'};
else
    mergedtitles = {'rec number' 'PE' 'FLS' 'CHL' 'SSC' 'CHLpk1' 'CHLpk2' 'Class'};
end;

%beadmatchtitles = {'start time (matlab days)' 'beadPE' 'beadFLS' 'beadCHL' 'beadSSC' 'beadnumber' 'bead acq time (min)' 'bead pump rate (ml/min)'};
beadmatchtitles = {'start time (matlab days)' 'beadPE' 'beadFLS' 'beadCHL' 'beadSSC' 'beadnumber' 'bead acq time (min)' 'analyzed volume (ml)'};  %april 2007
classnotes = 'Class numbers in last column of mergedwithclass: 1 = syn; 2=bright cryptos; 3 = junk w/pe; 4 = euks (i.e., no pe); 5 = euk junk; 6 = dim cryptos';
numcluster = 6;

eval(['load ' beadpath 'beadresults'])  %load bead result file
%beadresults = ones(1,10);

culture = cellport;  %port for samples
clear cell*
cellrestitles = {'mean start time (matlab days)' 'acq time (min)' 'volume analyzed (ml)'};
for typenum = 1:size(filetypelist,1),  
    filelist = dir([procpath filetypelist(typenum,:) '*.mat']);
    filelistmain = filelist;
    if year2do <= 2005
        [~,fileorder] = sort(str2num(char(regexprep(regexprep({filelist.name}, '.mat', ''), filetypelist(typenum,:), ''))));
        filelistmain = filelist(fileorder); %consecutive order
    end;
    if year2do == 2008 %special case dealing with day of mixed local and UTC time stamps (22 Oct 2008)
        ii1 = strmatch('FCB1_2008_296_092206', {filelistmain.name});
        ii2 = strmatch('FCB1_2008_296_130826',{filelistmain.name});
        ii3 = strmatch('FCB1_2008_296_114008',{filelistmain.name});
        filelistmain(sort([ii1,ii2,ii3])) = filelistmain([ii1,ii2,ii3])
    end;
    clear temp date fileorder
    filesections = ceil(length(filelistmain)/setsize);
    for sectcount = 1:filesections;
        if sectcount < filesections,
            filelist = filelistmain((sectcount-1)*setsize+1:sectcount*setsize);
        else
            filelist = filelistmain((sectcount-1)*setsize+1:end);
        end;
        eval(['load ' timepath filetypelist(typenum,:) 'time_' num2str(sectcount)])  %load file with processed time
        eval(['totaltime = ' filetypelist(typenum,:) 'time; clear ' filetypelist(typenum,:) 'time']) 
        %    pumprate = 0.05;  %assume for all of OC382
        
        timesectionendbin = find(diff(floor(totaltime(:,2)/timeinterval)));  %location of hour changes, last point in hr
        timesectionendbin =  [timesectionendbin; size(totaltime,1)];
        %timesectionendbin = find(totaltime(:,6) == 99);  %these are gaps between sets (as in lab)
        %timesectionenedbin = timesectionendbin(2:2:end);  %skip odd gaps for 2 culture alternation -- NOT GENERAL
        %    timesectionendbin =  [timesectionendbin; size(totaltime,1)];
        
        timestartind = 1;
        %    timestartind = timesectionendbin(1);
        filenum = 1;
        filename = filelist(filenum).name;
        disp(filename)  
        eval(['load ' procpath filename])
        partialdatmerged = datmerged;
        for sectionnum = 1:length(timesectionendbin),
            % for sectionnum = 1:length(timesectionendbin)-1,
            %disp(['sectionnum ' num2str(sectionnum)])
            timeendind = timesectionendbin(sectionnum);
            %timeendind = timesectionendbin(sectionnum+1);
            %following for case where start at sectionnum > 1, otherwise could reinit timestartind at end of loop with partialdatmerged
            if sectionnum > 1, timestartind = timesectionendbin(sectionnum-1) + 1; end;
            %if sectionnum > 1, timestartind = timesectionendbin(sectionnum) + 1; end;
            datendind = totaltime(timeendind,1);      
            while (partialdatmerged(end,1) < datendind) & filenum < length(filelist),  %keep adding on files until get full hour
                filenum = filenum + 1;    
                filename = filelist(filenum).name;
                disp(filename)
                eval(['load ' procpath filename])
                partialdatmerged = [partialdatmerged; datmerged];    
            end;
            clear datendind
            %        goodtimebins = find(totaltime(timestartind:timeendind,6) == S | totaltime(timestartind:timeendind,6) == 0);
            goodtimebins = find(totaltime(timestartind:timeendind,6) == culture);
            goodtimebins = goodtimebins + timestartind - 1;
            
            if ~isempty(goodtimebins),  %added 3/11/03 to handle sections with no good data
                datbins = [];
                for count = 1:length(goodtimebins),
                    if count == 1 & goodtimebins(1) == 1,
                        datbins = [datbins 1:totaltime(goodtimebins(1),1)];
                    else
                        datbins = [datbins totaltime(goodtimebins(count)-1,1)+1:totaltime(goodtimebins(count),1)];  
                    end;
                end;
                datbins = datbins-double(partialdatmerged(1,1)) + 1;  %index into existing partialdatmerged
                cellresults(sectionnum,1) = mean(totaltime(goodtimebins,2));  %mean start time (days)
                cellresults(sectionnum,2) = sum(totaltime(goodtimebins,4))/60;  %acqtime (min)
                cellresults(sectionnum,3) = sum(totaltime(goodtimebins,5));  %vol analyzed from syringe positions (ml)
                [junk, beadind] = min(abs(cellresults(sectionnum,1) - beadresults(:,1)));  
                
                beadmatch(sectionnum,1) = beadresults(beadind,1);
                beadmatch(sectionnum,2:7) = beadresults(beadind,[5:8,4,3]);
%                beadmatch(sectionnum,8) = NaN; %FIX later to have analvol %pumprate; %0.05;
                beadmatch(sectionnum,8) = beadresults(beadind,20); %April 2007, now analyzed ml
                clear junk beadind
                
                partialdatmerged = double(partialdatmerged);
                partialdatmerged(:,2:5) = partialdatmerged(:,2:5) + 1;
                
                a = find(partialdatmerged(datbins,4) ~= 1 & partialdatmerged(datbins,5) ~= 1);  %zero chl is not allowed...also skip 0 SSC
                datbins2 = datbins(a);
                clear a
                
                %figure(4),b = linspace(0,100,128); hist(partialdatmerged(partialdatmerged(:,2)<100,2),b)
                pecutoff = mode(partialdatmerged(:,2));
                if pecutoff > 1, pecutoff = 10^ceil(log10(pecutoff))*2; end;
                %disp(['pecutoff = ' num2str(pecutoff)])
                
                %consider PE/CHL and PE/SSC criteria to handle really bright euks when they have some signal on PE channel
                a = find(partialdatmerged(datbins2,4).^.8./partialdatmerged(datbins2,2) < 1); %rough cut
                datbins2pe = datbins2(a);
                clear a
                a = find(partialdatmerged(datbins2pe,2) > pecutoff & (partialdatmerged(datbins2pe,5)./partialdatmerged(datbins2pe,2) < 50 | partialdatmerged(datbins2pe,5) < 2e3));                    
                datbins2pe = datbins2pe(a);
                clear a
                datbins2nope = setdiff(datbins2, datbins2pe);
                classpe = (ones(size(datbins2pe))*1)';  %syn = class 1
                classnope = (ones(size(datbins2nope))*4)'; %euks = class 4
                if ~isempty(datbins2pe)
                    temp = partialdatmerged(datbins2pe,[4:5]);  %chl and ssc
                    tempind = find(temp(:,2) < 5e3);  %crude SSC screening to cut out junk   
                    maxvalue = 1e6;  
                    bins = 10.^(0:log10(maxvalue)/63:log10(maxvalue));  %make 64 log spaced bins
                    [nmergedhist,x,nbins] = histmulti5(temp(tempind,:),[bins' bins']);
                    [y,ind] = max(nmergedhist(:));
                    [i,j] = ind2sub(size(nmergedhist),ind);
                    tempmode = [i,j];
                    tempmode = bins(tempmode);
                    tempind = find(temp(:,2) <= tempmode(2)*5 & temp(:,2) >= tempmode(2)/5 & temp(:,1) < tempmode(1)*5 & temp(:,1) > tempmode(1)/5);
                    if size(tempind,1) < 2, %special crude case for very few points
                        tempind = find(temp(:,2) < 5e3);  %crude SSC screening to cut out junk   
                        tempmode = mean(temp(tempind,:));
                        tempind = find(temp(:,2) <= tempmode(2)*5 & temp(:,2) >= tempmode(2)/5 & temp(:,1) < tempmode(1)*5 & temp(:,1) > tempmode(1)/5);
                    end;
                    if ~isempty(tempind),
                        pedist = mahal(log10(temp),log10(temp(tempind,:)));  %distance of each point from cluster
                        threshhold = pedist_thre; %changed from 8 to 5 for 2006 and 2007, April 2007
                        junkind = find(pedist > threshhold);  %don't take all really small stuff
                        classpe(junkind) = 3; %reassign class to PE junk
                        clear temp
                    end;
               end;

                %now have first cut syn, find pe vs. chl slope
                temp = partialdatmerged(datbins2pe(classpe==1),[2,4]);
                lfit = polyfit(log10(temp(:,2)), log10(temp(:,1)),1);
                tempcoeff = 10.^(lfit(2)-.9); temppower = lfit(1); %0.9 with log10 shift for cutoff line for euks with pe
                clear temp

                %repeat steps above with better euk pe cutoff
                %consider PE/CHL and PE/SSC criteria to handle really bright euks when they have some signal on PE channel
                a = find(partialdatmerged(datbins2,4).^temppower./partialdatmerged(datbins2,2) < 1/tempcoeff);                    
                datbins2pe = datbins2(a);
                clear a
                a = find(partialdatmerged(datbins2pe,2) > pecutoff & (partialdatmerged(datbins2pe,5)./partialdatmerged(datbins2pe,2) < 50 | partialdatmerged(datbins2pe,5) < 2e3));                    
                datbins2pe = datbins2pe(a);
                clear a
                datbins2nope = setdiff(datbins2, datbins2pe);
                classpe = (ones(size(datbins2pe))*1)';  %syn = class 1
                classnope = (ones(size(datbins2nope))*4)'; %euks = class 4
                temp = partialdatmerged(datbins2pe,[4:5]);  %chl and ssc
                tempind = find(temp(:,2) < 5e3);  %crude SSC screening to cut out junk   
                maxvalue = 1e6;  
                bins = 10.^(0:log10(maxvalue)/63:log10(maxvalue));  %make 64 log spaced bins
                [nmergedhist,x,nbins] = histmulti5(temp(tempind,:),[bins' bins']);
                [y,ind] = max(nmergedhist(:));
                [i,j] = ind2sub(size(nmergedhist),ind);
                tempmode = [i,j];
                tempmode = bins(tempmode);
                tempind = find(temp(:,2) <= tempmode(2)*5 & temp(:,2) >= tempmode(2)/5 & temp(:,1) < tempmode(1)*5 & temp(:,1) > tempmode(1)/5);
                if length(tempind) < 2, %special crude case for very few points (e.g., first hr in FCB1_2009_099_213424)
                    tempind = find(temp(:,2) < 5e3);  %crude SSC screening to cut out junk   
                    tempmode = mean(temp(tempind,:));
                    tempind = find(temp(:,2) <= tempmode(2)*5 & temp(:,2) >= tempmode(2)/5 & temp(:,1) < tempmode(1)*5 & temp(:,1) > tempmode(1)/5);
                end;
                if ~isempty(tempind),
                    pedist = mahal(log10(temp),log10(temp(tempind,:)));  %distance of each point from cluster
                    threshhold = pedist_thre; %changed from 8 to 5 for 2006 and 2007, April 2007
                    junkind = find(pedist > threshhold);  %don't take all really small stuff
                    classpe(junkind) = 3; %reassign class to PE junk
                    clear temp
                    %end repeat


                    %now try to find regular cryptos (i.e., the ones bigger and brighter than syn)
                    tind = find(classpe == 1);  %SYN
                    % new crypto scheme 5-10-03, must be larger than syn mean on SSC and have high PE/CHL (beads are rel. low on PE/CHL, Heidi
                    tempmean = mean(partialdatmerged(datbins2pe(tind),5));  %mean ssc of syn
                    tempmean2 = mean(partialdatmerged(datbins2pe(tind),2));  %mean pe of syn
                    tind = find(partialdatmerged(datbins2pe(junkind),5) > tempmean*1.5 & partialdatmerged(datbins2pe(junkind),2) > tempmean2*.1 & partialdatmerged(datbins2pe(junkind),2)./partialdatmerged(datbins2pe(junkind),4) > 5e-2); 
                    classpe(junkind(tind)) = 6; %reassign class to "dim" cryptos
                    %next two lines added for "lg cryptos", Heidi 6/2/03
                    tind = find(partialdatmerged(datbins2pe(junkind),2) > 5e4); %PE above cutoff
                    classpe(junkind(tind)) = 2; %reassign class to "bright" cryptos
                    clear tind tempmean junkind tempmedian pedist threshhold chlcutoff tempind               

                    %now consider cluster of syn points on PE vs. SSC and add back any within threshold
                    temp = partialdatmerged(datbins2pe,[2,5]);  %pe and ssc
                    tempind = find(classpe == 1);
                    pedist = mahal(log10(temp), log10(temp(tempind,:)));
                    synind = find(pedist < pedist_thre);
                    classpe(synind) = 1;
                    clear temp pedist threshhold    
                end;              
                %now do junk elimination for euks        
                coeff = chljunk_coeff; %change from .04 to .01, 7-8-03, back to .04, 11/6/03, back to .01 for lab VolCal, 4-13-05; 4-18-06 for dock change to 0.1 (from .05)
                power = chljunk_power; %change from 1 to 1.1 from MVCO_May2003, 5-11-03 Heidi; change from 1.1 to .8 for lab VolCal, 4-10-05 heidi          
                %Mar 2007 - add chl threshold to eliminate new noise on chl baseline
                temp = partialdatmerged(datbins2nope,[4:5]);  %chl and ssc
                if ~isempty(temp)
                    % tempind = find(temp(:,1) >  coeff.*temp(:,2).^power & temp(:,1) < 1e4);  %line on chl v. ssc for junk cutoff, plus only consider chl < 1e4 for smallest euk peak
                    tempind = find(temp(:,1) >  coeff.*temp(:,2).^power & temp(:,1) > 300 & temp(:,1) < 4e3);  %line on chl v. ssc for junk cutoff, plus only consider 100 < chl < 3e3 for smallest euk peak
                    maxvalue = 1e6;  %is this too high?
                    bins = 10.^(0:log10(maxvalue)/63:log10(maxvalue));  %make 1024 log spaced bins
                    [nmergedhist,x,nbins] = histmulti5(temp(tempind,:),[bins' bins']);
                    [y,ind] = max(nmergedhist(:));
                    [i,j] = ind2sub(size(nmergedhist),ind);
                    tempmode = [i,j];
                    tempmode = bins(tempmode);
                    
                    %tempind = find(temp(:,2) <= tempmode(2)*5 & temp(:,2) >= tempmode(2)/5 & temp(:,1) < tempmode(1)*5 & temp(:,1) > tempmode(1)/5);
                    tempind = find(temp(:,2) <= tempmode(2)*2 & temp(:,2) >= tempmode(2)/5 & temp(:,1) < tempmode(1)*2 & temp(:,1) > tempmode(1)/5); %change to tighten up euk cluster (handling too much debris taken in Nov 2013, etc.)
                    if length(tempind) > 2, %~isempty(tempind),
                        coeff = 10.^(log10(tempmode(1))-power*log10(tempmode(2))-0.5); %disp(coeff)
                        
                        nopedist = mahal(log10(temp),log10(temp(tempind,:)));  %distance of each point from cluster
                        %              threshhold = 8;     %2/25/03 switched back to 10 (from 5) for syn_lab, 6/2/03 changed from 4 to 5; 7/8/03 changed from 5 to 10
                        threshhold = 5; %change from 6 to 5, Jan 2015 trying to address too much debris in euk cluster at some times in late 2013
                        %pedist_thre; %changed from 8 to 5 for 2006 and 2007, April 2007
                        %                junkind = find(pedist > threshhold | (partialdatmerged(datbins2pe,4) >= tempmedian(1)*5 | partialdatmerged(datbins2pe,5) >= tempmedian(2)*5));
                        junkind = find(nopedist > threshhold & ((temp(:,2) < tempmode(2)/2 & temp(:,1) < tempmode(1)) | (temp(:,1) < tempmode(1)/2) | temp(:,1) <  coeff.*temp(:,2).^power));  %don't take all really small stuff
                        % keyboard
                    else
                        junkind = find(temp(:,1) <  coeff.*temp(:,2).^power);
                    end;
                    classnope(junkind) = 5; %reassign class to euk junk
                    %tempind = find(temp(2) > tempmode(2) & temp(1) > tempmode(1) & tempind = find(temp(:,1) >  coeff.*temp(:,2).^power,
                end;
       %          keyboard
                
                %classnope(temp) = 5;
              %  figure(3), clf, b = logspace(2,6,128);
              %  subplot(1,3,1), loglog(partialdatmerged(datbins2nope,5), partialdatmerged(datbins2nope,4), '.')
              %  subplot(1,3,2), hist(partialdatmerged(datbins2nope,4),b), set(gca, 'xscale', 'log', 'xlim', [1e2 1e6])
              %  subplot(1,3,3), hist(partialdatmerged(datbins2nope(classnope==4),4),b), set(gca, 'xscale', 'log', 'xlim', [1e2 1e6])
                %keyboard
                %March 2007 - add criterion of PE > 1e3 since some bright euks now seem to be in the window previously used to cut out beads on chl v. fls
                %%temp = find(partialdatmerged(datbins2axnope,4) > partialdatmerged(datbins2nope,3)*5 + 5e4 & partialdatmerged(datbins2nope,2) > 1e3);                    
                %temp = find(partialdatmerged(datbins2nope,4) > 5e4 & partialdatmerged(datbins2nope,3) < 5000 & partialdatmerged(datbins2nope,2) > 1e3 & partialdatmerged(datbins2nope,2)./partialdatmerged(datbins2nope,4) > 0.01);                    
                %classnope(temp) = 5;
                %eliminate beads with case of high PE bright euks
             % %  temp = find(partialdatmerged(datbins2nope,4) > partialdatmerged(datbins2nope,3)*5 + 5e4);                    
% %                temp = find(partialdatmerged(datbins2nope,4)./partialdatmerged(datbins2nope,3) > 10);
% %                classnope(temp) = 5;
                tdata = partialdatmerged(datbins2nope,2:5); tbd = beadmatch(sectionnum,2:5); 
                %temp = find(tdata(:,1)>tbd(1)/2 & tdata(:,1)<tbd(1)*6 & tdata(:,2)>tbd(2)/2 & tdata(:,2)<tbd(2)*6 & tdata(:,3)>tbd(3)/2 & tdata(:,3)<tbd(3)*6 &tdata(:,4)>tbd(4)/2 & tdata(:,4)<tbd(4)*6);
                temp = find(tdata(:,1)>tbd(1)/2 & tdata(:,1)<tbd(1)*6 & tdata(:,3)>tbd(3)/2 & tdata(:,3)<tbd(3)*6 &tdata(:,4)>tbd(4)/2 & tdata(:,4)<tbd(4)*6);
                classnope(temp) = 5; %disp(length(temp))
                tdata = partialdatmerged(datbins2pe,2:5); tbd = beadmatch(sectionnum,2:5);
                %temp = find(tdata(:,1)>tbd(1)/2 & tdata(:,1)<tbd(1)*6 & tdata(:,2)>tbd(2)/2 & tdata(:,2)<tbd(2)*6 & tdata(:,3)>tbd(3)/2 & tdata(:,3)<tbd(3)*6 &tdata(:,4)>tbd(4)/2 & tdata(:,4)<tbd(4)*6);
                temp = find(tdata(:,1)>tbd(1)/2 & tdata(:,1)<tbd(1)*6 & tdata(:,3)>tbd(3)/2 & tdata(:,3)<tbd(3)*6 &tdata(:,4)>tbd(4)/2 & tdata(:,4)<tbd(4)*6);
                classpe(temp) = 5; %disp(length(temp))
%keyboard
                clear temp %power coeff
                %if intersect(filename(1:4), ['my15'; 'my16'; 'my17'; 'my18'], 'rows')
                %    keyboard
                %    temp = find(partialdatmerged(datbins2nope,4) < 100);
                %    classnope(temp) = 5;                
                %end;
                if plotflag,%~mod(sectionnum+2,4), %mod(sectionnum,6) == 1,   %make surf plots
                    maxvalue = 1e6;  %is this too high?
                    bins = 10.^(0:log10(maxvalue)/127:log10(maxvalue));  %make 256 log spaced bins
                    maxvalueSSC = 1e7;  %is this too high?
                    binsSSC = 10.^(0:log10(maxvalueSSC)/127:log10(maxvalueSSC));  %make 256 log spaced bins
                    figure(1)
                    clf
                    subplot(221)
                    [n,x] = histmulti5(partialdatmerged(datbins,[3:4]), [bins' bins']);
                    ind = find(n == 0); n(ind) = NaN;
                    surf(x(:,1), x(:,2), log10(n)')
                    ylabel('CHL'), xlabel('FLS')
                    set(gca, 'xscale', 'log', 'yscale', 'log')
                    shading flat
                    axis([1 1e6 1 1e6])
                    view(2)
                    title(datestr(cellresults(sectionnum,1)))
                    subplot(222)        
                    [n,x] = histmulti5([partialdatmerged(datbins,5), partialdatmerged(datbins,2)], [binsSSC' bins']);
                    ind = find(n == 0); n(ind) = NaN;
                    surf(x(:,1), x(:,2), log10(n)')
                    ylabel('PE'), xlabel('SSC')
                    set(gca, 'xscale', 'log', 'yscale', 'log')
                    shading flat
                    view(2)
                    axis([1 1e7 1 1e6])
                    subplot(223)
                    [n,x] = histmulti5([partialdatmerged(datbins,5), partialdatmerged(datbins,4)], [binsSSC' bins']);
                    ind = find(n == 0); n(ind) = NaN;
                    surf(x(:,1), x(:,2), log10(n)')
                    ylabel('CHL'), xlabel('SSC')
                    set(gca, 'xscale', 'log', 'yscale', 'log')
                    shading flat
                    view(2)
                    axis([1 1e7 1 1e6])
                    subplot(224)
                    %        [n,x] = histmulti5([partialdatmerged(datbins2pe,5), partialdatmerged(datbins2pe,4)], [bins' bins']);
                    [n,x] = histmulti5([partialdatmerged(datbins2pe,4), partialdatmerged(datbins2pe,2)], [bins' bins']);
                    ind = find(n == 0); n(ind) = NaN;
                    surf(x(:,1), x(:,2), log10(n)')
                    hold on
                    loglog([1:10:1e5], 10.^(log10([1:10:1e5])*fit(1) + fit(2)), 'r')
                    %ylabel('CHL'), xlabel('SSC')
                    ylabel('PE'), xlabel('CHL')
                    set(gca, 'xscale', 'log', 'yscale', 'log')
                    shading flat
                    view(2)
                    axis([1 1e6 1 1e6])
                    %        title('PE containing cells only')
                    clear maxvalue bins
                end;
                
                colorstr = ['r', 'b', 'k', 'g', 'y', 'c', 'm'];
                
                %        numcluster = numclusterpe + numclusternope;
                %        numcluster = 5;
                
                mergedwithclass = [partialdatmerged NaN*ones(size(partialdatmerged,1),1)];
                mergedwithclass(datbins2pe,end) = classpe;
                %    mergedwithclass(datbins2nope,end) = classnope + numclusterpe;  %euks class nums start after pe cells
                mergedwithclass(datbins2nope,end) = classnope;  
                mergedwithclass = mergedwithclass(datbins,:);
                clear classpe classnope
                if plotflag, %~mod(sectionnum+2,4), %mod(sectionnum,6) == 1, %make cluster plots
                    figure(2)
                    clf, 
                    subplot(221)
                    hold on
                    ylabel('CHL'), xlabel('FLS')
                    for c = 1:numcluster,
                        ind = find(mergedwithclass(:,end) == c);
                        eval(['loglog(mergedwithclass(ind,3),mergedwithclass(ind,4), ''' colorstr(c) 'o'', ''markersize'', 1)'])
                    end;
                    set(gca, 'xscale', 'log', 'yscale', 'log')
                    axis([1 1e6 1 1e6])
                    title(datestr(cellresults(sectionnum,1)))
                    %X = 1:1000:1e6; plot(X,X*5+50000, 'k-') 
                    %line([1 5000], [5e4 5e4], 'color', 'k'), line([5000 5000], [5e4 1e6], 'color', 'k')
                    subplot(222)        
                    hold on
                    ylabel('PE'), xlabel('SSC')
                    for c = 1:numcluster,
                        ind = find(mergedwithclass(:,end) == c);
                        eval(['loglog(mergedwithclass(ind,5),mergedwithclass(ind,2), ''' colorstr(c) 'o'', ''markersize'', 1)'])
                    end;
                    set(gca, 'xscale', 'log', 'yscale', 'log')  
                    fplot('x/50', [1 1e6], 'linestyle', '--')
                    axis([1 1e7 1 1e6])
                    subplot(223)
                    hold on
                    ylabel('CHL'), xlabel('SSC')
                    for c = 1:numcluster,
                        ind = find(mergedwithclass(:,end) == c);
                        eval(['loglog(mergedwithclass(ind,5),mergedwithclass(ind,4), ''' colorstr(c) 'o'', ''markersize'', 1)'])
                    end;
                    set(gca, 'xscale', 'log', 'yscale', 'log')
                    set(gca, 'Ygrid', 'on')
                    axis([1 1e7 1 1e6])
                    plot(tempmode(2), tempmode(1), '^k', 'markerfacecolor', 'k', 'markersize',8)
                    fplot([num2str(coeff) '*x.^' num2str(power)], [10 1e6], 'linestyle', '--')
                    subplot(224)
                    hold on
                    ylabel('PE'), xlabel('CHL')
                    for c = 1:numcluster,
                        ind = find(mergedwithclass(:,end) == c);
                        eval(['loglog(mergedwithclass(ind,4),mergedwithclass(ind,2), ''' colorstr(c) 'o'', ''markersize'', 1)'])
                    end;
                    loglog([1:10:1e5], 10.^(log10([1:10:1e5])*fit(1) + fit(2)), 'r')
                    set(gca, 'xscale', 'log', 'yscale', 'log')
                    fplot([num2str(tempcoeff) '*x.^' num2str(temppower)], [10 1e6], 'linestyle', '--')
                    axis([1 1e6 1 1e6])
                    disp('pause for graphs...')
                    pause %(0);
                    disp('reading next...')
                end;  %if 1, (to plot)
                
                maxvalue = 1e6;  %is this too high?
                bins = 10.^(0:log10(maxvalue)/255:log10(maxvalue));  %make 256 log spaced bins
                maxvalueSSC = 1e7;  %is this too high?
                binsSSC = 10.^(0:log10(maxvalueSSC)/255:log10(maxvalueSSC));  %make 256 log spaced bins                
                for c = 1:numcluster,
                    ind = find(mergedwithclass(:,end) == c);
                    cellNUM(sectionnum,c) = length(ind);
                    if length(ind) > 1,
                        n = hist(mergedwithclass(ind,2:4), bins);
                        [junk, maxind] = max(n);
                        n2 = hist(mergedwithclass(ind,5), binsSSC);
                        [junk, maxind2] = max(n2);
                        cellPEmode(sectionnum,c) = bins(maxind(1));  
                        cellFLSmode(sectionnum,c) = bins(maxind(2));  
                        cellCHLmode(sectionnum,c) = bins(maxind(3));  
                        cellSSCmode(sectionnum,c) = binsSSC(maxind2); 
                        cellPE(sectionnum,c) = mean(mergedwithclass(ind,2));  %mean params
                        cellFLS(sectionnum,c) = mean(mergedwithclass(ind,3));  %mean params
                        cellCHL(sectionnum,c) = mean(mergedwithclass(ind,4));  %mean params
                        cellSSC(sectionnum,c) = mean(mergedwithclass(ind,5));  %mean params
                        clear n junk maxind
                    else
                        cellPE(sectionnum,c) = NaN;  
                        cellFLS(sectionnum,c) = NaN;  
                        cellCHL(sectionnum,c) = NaN;  
                        cellSSC(sectionnum,c) = NaN;
                        cellPEmode(sectionnum,c) = NaN;  
                        cellFLSmode(sectionnum,c) = NaN;  
                        cellCHLmode(sectionnum,c) = NaN;  
                        cellSSCmode(sectionnum,c) = NaN;
                    end;  %if ~isempty(ind)
                end; %for c = 1:numcluster
                clear c ind maxvalue bins 
                
                allmergedwithclass{sectionnum} = mergedwithclass;
            else
                allmergedwithclass{sectionnum} = NaN;
                cellPE(sectionnum,1:numcluster) = NaN;
                cellFLS(sectionnum,1:numcluster) = NaN;
                cellCHL(sectionnum,1:numcluster) = NaN;
                cellSSC(sectionnum,1:numcluster) = NaN;
                cellPEmode(sectionnum,1:numcluster) = NaN;
                cellFLSmode(sectionnum,1:numcluster) = NaN;
                cellCHLmode(sectionnum,1:numcluster) = NaN;
                cellSSCmode(sectionnum,1:numcluster) = NaN;
                cellNUM(sectionnum,1:numcluster) = NaN;
                cellresults(sectionnum,1:3) = NaN;
                beadmatch(sectionnum,1:8) = NaN;
            end; %if ~isempty(goodtimebins)
            %get ready for next loop           
            partialdatmerged = datmerged;  %reset partialdat with file partly completed
        end; %sectionnum = 1:length(timesectionendbin)
        mergedwithclass = allmergedwithclass;

        eval(['save ' groupedpath filetypelist(typenum,:) '_' num2str(sectcount) ' beadmatch* cell* classnotes'])
        eval(['save ' mergedpath filetypelist(typenum,:) 'merged_' num2str(sectcount) ' merged*'])
        clear beadmatch cellresults mergedwithclass link* allmergedwithclass cellNUM cellPE cellFLS cellCHL cellSSC cell*mode
        clear datbins datbins2* goodtimebins fit fittitles sectionnum
    end; %for sectcount
end; %for typenum = 1:length(filetypelist)

%end; %for count = 1:2

clear count culture typenum numcluster dattitles datmerged partialdatmerged cell*mode
clear timeinterval time*ind timesectionendbin totaltime timetitles mergedtitles cellrestitles classnotes colorstr
clear beadresults beadtitles beadmatchtitles
clear filelist filenum filename ans