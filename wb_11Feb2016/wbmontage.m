%function wbmontage(wbstruct,options)
%plot and make a pdf of a montage with labeled blob centers

c
make_it_tight = true;
subplot = @(m,n,p) subtightplot (m, n, p, [0 0], [0 0], [0 0]);
if ~make_it_tight,  clear subplot;  end

%general options
options.frame=1;    
options.outputFolder=pwd;
options.labelsFlag=true;

%layout options
options.nrows=2;
options.width=1200;
%options.rowheight=600;  %forcing normal aspect ratio.

%histogram options
options.colormap=hot(256);

options.equalizeFlag=true;
options.fixMaxScale=true;
options.blackFloorMargin=2500;
options.globalBrightness=2;

%exclusion options
options.exclusionList=[]; %48:141;
    



folder=pwd;

%load images
%load ZMIPS

%if nargin<1 || isempty(wbstruct)
    if exist('Quant/wbstruct.mat','file')
        load('Quant/wbstruct.mat');
    elseif exist('wbstruct.mat','file')
        load('wbstruct.mat');
    elseif exist('../Quant/wbstruct.mat','file')
        load('../Quant/wbstruct.mat');
    end
%end

flagstr=[];
if options.exclusionFlag
    flagstr=[flagstr '-exc'];
end

if ~options.labelsFlag
    flagstr=[flagstr '-nolabels'];
end

trialname=folder(max(strfind(folder,'/'))+1:end);
fnames=dir([folder '/*.tif']);
displayname=strrep(trialname,'_','\_');    
Iglobalmax=0;
Iglobalmin=4096;
for i=1:length(fnames)
   
    I(i)=tiffread2([folder '/' fnames(i).name]);
    Iglobalmin=min([Iglobalmin min(I(i).data(:))]);
    Iglobalmax=max([Iglobalmax max(I(i).data(:))]);

    [maxval maxind]=max(hist(single(I(i).data(:))));

    I(i).data(I(i).data<=maxind+options.blackFloorMargin)=I(i).data(I(i).data<=maxind+options.blackFloorMargin)-( maxind+options.blackFloorMargin-  I(i).data(I(i).data<=maxind+options.blackFloorMargin)   )    ;
    
end

ncols=ceil(length(I)/options.nrows);
imagePlotWidth=options.width/ncols;
imagePlotHeight=I(1).height/I(1).width*imagePlotWidth;



%   figure('Position',[0 0 0.9*length(I)*I(1).width I(1).height]);
figure('Position',[0 0 options.width imagePlotHeight*options.nrows]);


for i=1:length(I)

    ax(i)=subplot(options.nrows,ncols,i);

    if options.equalizeFlag
        if options.fixMaxScale
             imagesc(I(i).data,[min(I(i).data(:)) Iglobalmax/options.globalBrightness]);
        else
             imagesc(I(i).data);
        end
    else
        imagesc(double(I(i).data));
    end
    hold on;

    colormap(options.colormap);
    axis image;
    axis off;

    
end

%draw blob labels

if options.labelsFlag
    
    exclusionNumbering=1;
    for i=1:length(I)

       axes(ax(i));
       for b=1:wbstruct.nn  %length(blobs.unsortedparentlist)

             if wbstruct.blobs_sorted.z(wbstruct.blobs.parentlist(wbstruct.neuronlookup(b))) == i
                 if ~ismember(b,options.exclusionList)
                     ex(wbstruct.blobs_sorted.x(wbstruct.blobs.parentlist(wbstruct.neuronlookup(b))),wbstruct.blobs_sorted.y(wbstruct.blobs.parentlist(wbstruct.neuronlookup(b))),4,[0 1 0]);
                     text(wbstruct.blobs_sorted.x(wbstruct.blobs.parentlist(wbstruct.neuronlookup(b))),wbstruct.blobs_sorted.y(wbstruct.blobs.parentlist(wbstruct.neuronlookup(b))),[' ' num2str(exclusionNumbering)],'Color',[0 1 0],'VerticalAlignment','top');
                     exclusionNumbering=exclusionNumbering+1;
                 end
             end
       end

       %intitle(['Z' num2str(i)]);
    end

end


tightfig;
save2pdf([options.outputFolder '/wb-LabeledMontage-T' num2str(options.frame) flagstr '.pdf']);
