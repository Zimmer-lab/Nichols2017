function wbStateStatsStruct=wbTimeColoringTrialAvg(wbStateStatsStruct,dt,maxTime)


if nargin<3
    maxTime=1080;
end

if nargin<2
    dt=1/10;
end

wbStateStatsStruct.commonTV=0:dt:maxTime;

for i=1:length(wbStateStatsStruct.traceColoring)   

   upStateTrace=double(wbStateStatsStruct.traceColoring{i}==2);
   upOrHiStateTrace=double(wbStateStatsStruct.traceColoring{i}==2 | wbStateStatsStruct.traceColoring{i}==3);
   hiStateTrace=double(wbStateStatsStruct.traceColoring{i}==3);

   wbStateStatsStruct.upStateTraceCommonTimeBase(:,i)=interp1(wbStateStatsStruct.tv{i},upStateTrace,wbStateStatsStruct.commonTV,'nearest'); 
   wbStateStatsStruct.upOrHiStateTraceCommonTimeBase(:,i)=interp1(wbStateStatsStruct.tv{i},upOrHiStateTrace,wbStateStatsStruct.commonTV,'nearest'); 
   wbStateStatsStruct.upOrHiStateTraceCommonTimeBase(:,i)=interp1(wbStateStatsStruct.tv{i},upOrHiStateTrace,wbStateStatsStruct.commonTV,'nearest'); 
   wbStateStatsStruct.hiStateTraceCommonTimeBase(:,i)=interp1(wbStateStatsStruct.tv{i},hiStateTrace,wbStateStatsStruct.commonTV,'nearest'); 

end
