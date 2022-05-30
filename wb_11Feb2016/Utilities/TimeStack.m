function [stacked_traces,tv]=TimeStack(trace,stacklength,interval,numstacks,start,dt,matchbaselineflag)
%stacked_traces=timestack2(trace,stacklength,interval,numstacks,start,matchbaselineflag)
%TIMESTACK2  Split a trace into time segments and stack them in an array
%
%  trace: vector trace of data
%  stacklength: length of one stack, in number of samples
%  interval:  spacing, in samples, of successive stacks
%  start: starting sample# of first stack, default 1
%  numstacks: number of stacks to make, default maximum amount
%  matchbaselineflag:  if 1, then subtract off initial value of each stack
%
%  outputs an array of stacks with dimension (stacklength,numstacks)
%
%  example:  
%      trace=1:500;
%      plot(timestack(trace,20,[],5,10));
%
%  will split trace into 10 stacks of length 20, starting at t=5, and
%
%  V2 5/15/13
%  V0.6  6/20/11
%  V0.5  11/23/09
%
%  Saul Kato
%


nsamples=length(trace);


if nargin<7
    matchbaselineflag=0;
end

if nargin<6
   dt=1;
end

if nargin<3 || isempty(interval)
   interval=stacklength;    
end

if nargin<4 || numstacks==-1
   numstacks=floor((nsamples-stacklength)/interval);
end

tracecount=0;
for i=1:numstacks
    stacked_traces(:,tracecount+1)=trace((tracecount*interval+start)...
     :(tracecount*interval+stacklength+start-1));
    
    if matchbaselineflag==1
        stacked_traces(:,tracecount+1)=stacked_traces(:,tracecount+1)-stacked_traces(1,tracecount+1);
    elseif matchbaselineflag==2
        stacked_traces(:,tracecount+1)=stacked_traces(:,tracecount+1)-stacked_traces(1,tracecount+1);
    end   
    tracecount=tracecount+1;
end

tv=mtv(stacked_traces(:,1),dt);

end

