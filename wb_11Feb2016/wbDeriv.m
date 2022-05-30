function derivTraces=wbDeriv(traces,method,param1,param2)
% derivTraces=wbDeriv(traces,method,param1,param2)
% compute derivative on a batch of traces
% support old smoothed differencing method and variational regularized
% method

if nargin<2
    method='old';
end


%doubly smoothed derivative
%

if strcmp(method,'old')
    derivTraces= fastsmooth(deriv(fastsmooth(traces,5,3,1)) ,10,3,1);
else  %reg
    derivTraces=derivReg(traces,param1,param2);
    
end