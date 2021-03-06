function [] = process_attune(cruiseName, basepath)
%input basepath to
%Cruise\ with ExportedFCS and Summary

Attune.cruiseName = cruiseName;
fpath = [basepath '\ExportedFCS\'];
outpath = [basepath '\Summary\'];

% Extracting files out of the directory sorts NES out from SFD
%first it will populate with NES titled files but if empty will go for SFD
%file string
filelist = dir([fpath 'NES*']); 
if isempty(filelist) == 1
     filelist = dir([fpath 'SFD*']);
end

filelist = {filelist.name}';

[Attune.FCSfileinfo] = FCS_DateTimeList(fpath)

% Creating the variables
Attune.FCSfileinfo.vol_analyzed = [];

Attune.Count.lesstwo = [];
Attune.Count.twoten = [];
Attune.Count.tentwen =[];
Attune.Count.twen = [];

Attune.Biovol.lesstwo = [];
Attune.Biovol.twoten = [];
Attune.Biovol.tentwen =[];
Attune.Biovol.twen = [];
Attune.Biovol.Syn = [];

Attune.Count.SynTotal = [];
Attune.Count.SynYCV = [];
Attune.Count.EukTotal = [];

for count = 1:length(filelist)
    
    disp([num2str(count) ' of ' num2str(length(filelist))])
    filename = [fpath filelist{count}];
    
    %reading in each FCS file with fca_readfcs
    [~,fcshdr,fcsdatscaled] =fca_readfcs(filename);
    
    %Vector to indicate class of each event
    class = zeros(numel(fcsdatscaled(:,1)),1)
    
    %Channels for Syn
    synSignal = fcsdatscaled(:,11);%PE Signal GL1-H
    fscSignal =fcsdatscaled(:,19);%FSC
    
    %Channels for Eukaryotes
    ssc_signal = fcsdatscaled(:,3);%SSC
    y_signal =fcsdatscaled(:,15);%BL1
   
    %defining the polygon gate for the Small Eukaryote Signal
    x_polygon = [10^1.5  50   10^4 10^6 10^6   10^5    10^4.3  10^3.7  10^2.8      10^1.5 ];
    y_polygon = [10^2.8  3500 10^6 10^6 10^5.5 10^4.8  10^4.2  10^3.7  10^3        10^2.8 ];
    
    %defining the rectangular gate for the Synechecoccus Signal
    SynXmin= 200;
    SynXmax= 10^4;
    SynYmin= 10^3;
    SynYmax= 10^5;
    x_rect = [SynXmin SynXmin SynXmax SynXmax SynXmin];
    y_rect = [SynYmin SynYmax SynYmax SynYmin SynYmin];
    
   %counting cells within the gates
   in_euk = inpolygon(ssc_signal,y_signal,x_polygon,y_polygon);
   in_syn = inpolygon(synSignal,fscSignal,x_rect,y_rect);
   
   %defining euks and syn in the class
   class(find(in_euk == 1)) = 1
   class(find(in_syn == 1)) = 2
   
    %for euks
    ssc = log10(ssc_signal(find(class==1)));
    
    %for syn
    SynSsc = log10(synSignal(find(class ==2)));
    
    %for %CV
    SynY = fscSignal(find(class ==2));
   
    %Coefficient of Variation
    SynYCV = (std(SynY)./mean(SynY)).*100;
 
    %volume from scattering for euks
    volume = 1.3.*ssc - 2.9;
    lin_vol = 10.^(volume);
    diameter = ((lin_vol/pi).*(3/4)).^(1/3);
    
    %volume from scattering conversion for syn
    SynVolume = 1.3.*SynSsc - 2.9;
    lin_SynVol = 10.^(SynVolume);
    SynDiameter = ((lin_SynVol/pi).*(3/4)).^(1/3);
   
 size2 = [];
 size2_10 =[];
 size10_20 = [];
 size20 = [];
 for ii = 1:length(diameter)
    if diameter(ii) <= 2
        size2 = [size2;diameter(ii)];
    elseif diameter(ii)>= 2 & diameter(ii) <= 10
        size2_10 = [size2_10;diameter(ii)];
    elseif  diameter(ii)>= 10 & diameter(ii) <= 20
        size10_20 =[size10_20; diameter(ii)];
    elseif diameter(ii) >= 20 
        size20 =[ size20;diameter(ii)];
    end
 end
 
   Attune.Biovol.lesstwo = [Attune.Biovol.lesstwo; sum((4/3).*pi.*((size2./2).^3))];
   Attune.Biovol.twoten = [Attune.Biovol.twoten; sum((4/3).*pi.*((size2_10./2).^3))];
   Attune.Biovol.tentwen =[Attune.Biovol.tentwen; sum((4/3).*pi.*((size10_20./2).^3))];
   Attune.Biovol.twen = [Attune.Biovol.twen; sum((4/3).*pi.*((size20./2).^3))];
   
   Attune.Biovol.Syn = [Attune.Biovol.Syn; sum((4/3).*pi.*((SynDiameter./2).^3))];
   Attune.Count.lesstwo = [Attune.Count.lesstwo ; length(size2)];
   Attune.Count.twoten = [Attune.Count.twoten ; length(size2_10)];
   Attune.Count.tentwen =[Attune.Count.tentwen ; length(size10_20)];
   Attune.Count.twen = [Attune.Count.twen ; length(size20)];
   Attune.Count.SynTotal = [Attune.Count.SynTotal; length(SynSsc)];
   Attune.Count.EukTotal = [Attune.Count.EukTotal; length(diameter)];
   Attune.FCSfileinfo.vol_analyzed = [Attune.FCSfileinfo.vol_analyzed; fcshdr.VOL];
   Attune.Count.SynYCV = [Attune.Count.SynYCV; SynYCV];
 
end
clear ii diameter size2_10 size10_20 size20 synYCV SynSsc SynDiameter volume ssc_signal y_signal synSignal fscSignal in_syn in_euk

sum(Attune.Count.lesstwo) + sum(Attune.Count.twoten) + sum(Attune.Count.tentwen) + sum(Attune.Count.twen) == sum(Attune.EukTotal) + sum(Attune.SynTotal)
Attune.readme = ['This was generated by process_attune.m which takes in a'...
    'directory of FCS files that should be called Exported FCS and outputs an'...
    'structure called Attune.']

save([basepath '\Summary'],Attune)
end 