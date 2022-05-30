% checking activity of a neuron.

DerivActive = 0.01< wbstruct.simple.derivs.traces(1200:1700,1:end);

FActive = 0.5< wbstruct.simple.deltaFOverF_bc(1200:1700,1:end);

Active = DerivActive + FActive;

Activesum =sum(Active);

Active2 = 0.9<Activesum;

sum(Active2)

% 31a N = 101
% 0.01 + 0.5 = 67 active (through whole)
% 0.01 + 0.5 = 22 active (1:1400,1:end)
% 
% 31b N =126
% 0.01 + 0.5 = 66 active (1:1400,1:end)
% 0.01 + 0.5 = 65 active (1500:2500,1:end)
% 0.01 + 0.5 = 62 active(1500:2000,1:end)
% 0.01 + 0.5 = 51 active (2000:2500,1:end)
% 0.01 + 0.5 = 17 active (3000:4200,1:end)
% 
% 20151112a N = 118
% 0.01 + 0.5 = 48 active(1500:2000,1:end)
% 0.01 + 0.5 = 16 active(600:1100,1:end) (quiet period)
% 
%N2 let AN20150312g
%0.01 + 0.5 = 22 active(600:1100,1:end)

%N2 let AN20150508a N 116
%0.01 + 0.5 = 36 active(1:500,1:end) ~2m 
%0.01 + 0.5 = 37 active(600:1100,1:end) ~2m 
%0.01 + 0.5 = 52 active(1200:1700,1:end) ~2m 
%0.01 + 0.5 = 51 active(1:1400,1:end)
