function [outtraces normvec]=normalize(traces,scale,normpoint,normendpoint)
% NORMALIZE  outtraces=normalize(traces,scale) normalizes a set of traces
% by a single value, typically max(abs(trace(:,i)))
%
%  traces: input traces, first dimension is time, second is trace#
%  scale:  rescale to max |value| (defaults to 1 if left blank)
%  normpoint:  specifies a time index whose value each trace will
%    be normalized to
%
% if scale=1, normalize by peak magnitude, i.e. max(abs(trace));
% if scale=0, normalize by unsigned area, i.e. sum(abs(trace));
% if scale=-1, normalize by variance. sum(trace.^2));
% if scale=2, normalize by signed area. sum(trace));
% if scale=3, normalize by rms
%
%  output is an array of normalized traces the same dimension as input
%
% 
%  with 3 arguments, normalize to a value at a specific time index at each
%  trace
%  with 4 arguments, normalize to a max within a specified time index range
%  Example 1:  normalize(traces,1) normalizes all traces to a max of 1.
%  Example 2: normalize(traces,100,400) normalizes all traces so they have
%      value 100 at time=400;
%
%  Version 0.2
%  Saul Kato  1/11/10 
%  updated 12/13/10
%  updated 2/9/11 added area normalization
%  updated 4/10/12 addded range max option


outtraces=traces;

if nargin<2
    scale=1;
end

if nargin<3
    normpoint=1;
end

if nargin<4
    normendpoint=size(traces,1);
end



if scale==0 %area normalize
    
    for i=1:size(traces,2)
        normvec(i)=sum(abs(traces(:,i)));
        outtraces(:,i)=traces(:,i)/normvec(i); 
    end

elseif scale==2 %signed area normalize
    
    for i=1:size(traces,2)
        normvec(i)=sum(traces(:,i));
        outtraces(:,i)=traces(:,i)/normvec(i); 
    end
    
elseif scale==3 %rms normalize
    
    for i=1:size(traces,2)
        normvec(i)=rms(traces(:,i));
        outtraces(:,i)=traces(:,i)/normvec(i); 
    end
    
elseif scale==4 %0-1 normalize
    
    for i=1:size(traces,2)
        normvec(i)=max(traces(:,i)-min(traces(:,i)));
        outtraces(:,i)=(traces(:,i)-min(traces(:,i)))/normvec(i); 
    end
       
elseif scale==-1  %variance norm with range
        
        for i=1:size(traces,2)
            normvec(i)=sum(traces(normpoint:normendpoint,i).^2);
            outtraces(:,i)=traces(:,i)/normvec(i);

        end
        
elseif scale==-2 %stdev heaviside norm with range
        
        for i=1:size(traces,2)
            normvec(i)=sum((traces(normpoint:normendpoint,i).*heaviside(traces(normpoint:normendpoint,i))).^2);
            outtraces(:,i)=traces(:,i)/normvec(i);

        end    
        
elseif scale==-3  %standardize  %PROBLEM there is no division by N-1
        
        for i=1:size(traces,2)
            normvec(i)=sqrt(sum(traces(normpoint:normendpoint,i).^2));
            outtraces(:,i)=traces(:,i)/normvec(i);

        end
        
else   %max norm with range
          for i=1:size(traces,2)
            normvec(i)=max(abs(traces(normpoint:normendpoint,i)));
            outtraces(:,i)=traces(:,i)/normvec(i)*scale;

          end      
end




end
