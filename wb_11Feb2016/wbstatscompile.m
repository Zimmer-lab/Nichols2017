%function [outp_cellarray dirnames]=wbstatscompile(statName)
%compile field from wbstats.mat structs

%     if nargin<1
%         statName='all';
%     end

    [outp_cellarray dirnames]=wbtreerun(@wbstats,pwd,{[],'all'},1);

%end
%
genos={'lite-1','eat-4','unc-7'};
outp_cellarray2=outp_cellarray(~cellfun('isempty',outp_cellarray));
dirnames2=dirnames(~cellfun('isempty',outp_cellarray));

%%
figure;
clear RMSdist;
bins=linspace(0,1,40);
for i=1:length(outp_cellarray2)
    
    RMSdist(:,i)=hist(outp_cellarray2{i}.RMS,bins);
    
    
    plot(bins,RMSdist(:,i),'Color',color(find(strncmp(wbgetgenotype(dirnames2{i}),genos,3)),3));
    hold on;
end
