close all;
clear all;

load('AVA20140513.mat')

%load('allstim21.mat');
%load('allstim4.mat');
% 
% 

SmoothFact = 30;  % flank size of smoothwindow (= 2* SmoothFact +1)

IncThresh = 0.03; % threshold of derivative to consider a true rise phase

DurationThresh = 3; % minimum time in frames that a rise phase should last


FinalTraceSmooth = 5; %smooth factor for plotting state inferred probability



alldata = AVA20140513';

%alldata = [allstim4, allstim21];

[NumSets, NumFrames] = size(alldata);

t=0:0.1:NumFrames/10;

t = t(2:end);

mnalldata = nanmean(alldata);

%figure; plot(mnalldata); title('unsmoothed average');


smdata = nanmoving_average(alldata,SmoothFact,2,0);  %data smoothening

mnsmdata = nanmean(smdata);



%figure; plot(mnsmdata); title('smoothed average');

figure; title('calcium traces');

NumRowsinPlot = ceil(NumSets/4);

for i = 1:NumSets
    
    subplot(NumRowsinPlot, 4, i);
    
    plot(t,alldata(i,:),'b');
    
    hold on
    
    plot(t,smdata(i,:),'r');
    
    
    title(['dataset' num2str(i)]);

    
    
end


d21=diff(smdata')';



dt=diff(t);

dtMat = [];

for i = 1:NumSets

dtMat(i,:)=dt;

end

d21dt = d21 ./ dtMat; %calculate derivative


figure; title('D[calcium traces] / dt');




for i = 1:NumSets
    
    subplot(NumRowsinPlot, 4, i);
    
    
    plot(t(2:end),d21dt(i,:),'b');
    
    
    title(['dataset' num2str(i)]);

    
end



mnd21dt = nanmean(d21dt);

%figure; plot(t(2:end),mnd21dt); title('mean derivative')

PosdCdT = d21dt > IncThresh; %creat logical that suggests rise phases

StateProbMat = zeros(NumSets,NumFrames-1);



for i = 1:NumSets %this loop finds connected components as defined by DurationThresh
    
    Con = bwconncomp(PosdCdT(i,:));
    
    TraceProps = regionprops(Con,'Area');
    
    RiseSegments = find([TraceProps.Area] > DurationThresh);
    
    for ii = 1:length(RiseSegments)
        
        StateProbMat(i,Con.PixelIdxList{RiseSegments(ii)}) = 1;
        
    end
   
    
    
end

StateProbMat(isnan(d21)) = NaN; %bring back NaNs that were lost when creating the logical array PosdCdT

StateProb = nanmean(StateProbMat);

 %%
figure; plot(t(11:end-10),StateProb(10:end-10));
axis([0 60 0 1]);
hold on;

smprob = nanmoving_average(StateProb(10:end-10),FinalTraceSmooth,2,0);

plot(t(11:end-10),smprob,'r','LineWidth',3);
%%

figure; title('inferred behavioral state');
imagesc(t,1:NumSets,StateProbMat,[0 1]);
colormap(flipud(gray));
ylabel('Dataset no.');
xlabel('time(s)');

%%

figure;
imagesc(d21dt);
colorbar;


figure;
imagesc(alldata);
colorbar;