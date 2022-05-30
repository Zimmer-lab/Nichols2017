function [autocorr_out,lagvec,autocorr_allout]=autocorr(traces,maxlag,dt,plotflag,detrendflag)
% auto=AUTOCORR(traces,windowsize,dt,plotflag)
% compute and optionally plot finite-window autocorrelation of an array of traces
% lagvec: timevector (x-axis) for plots
%
% autocorrelation is computed for a stepping time window, then averaged
% across a trace
%
% windowsize is in number of frames
%
% if windowsize=0 then use full trace
% if plotflag = false then suppress plots
% dt is only used for plotting
%
% uses xcorr
% Saul Kato
% 8/26/10
% updated 12/6/10  , 2014
% 

if (nargin<5) detrendflag=false; end
if (nargin<4) plotflag=true;  end
if (nargin<3) dt=0.05; end 
if (nargin<2) maxlag=0; end

T=size(traces,1);
numtraces=size(traces,2);

t_start=maxlag+1;
t_end=T-maxlag;

if detrendflag
    detrendType='linear';
else
    detrendType='constant';
end

if maxlag==0 %full trace, no window
    
    lagvec=(-(t_end-t_start):(t_end-t_start))'*dt;
    for i=1:numtraces    
        autocorr_out(:,i)=xcorr(traces(t_start:t_end,i),'coeff');
    end
    
    autocorr_allout=autocorr_out;
    
else  %averaged autocorrelations of sliding windows
       
    lagvec=(-maxlag:maxlag)'/dt;  %lagvec has length 2*maxlag+1
   
    autocorr_cum=zeros(length(lagvec),numtraces);
    
    autocorr_allout=zeros(length(lagvec),numtraces,length(t_start:maxlag:t_end));
    
    for i=1:numtraces
        
        tWindowVector=t_start %:maxlag*2:t_end;
        tCount=1;
        for t=tWindowVector

            
             fullxcorr=(xcorr(detrend(traces(t-maxlag:t+maxlag,i),detrendType),'coeff'));
             
             croppedxcorr=fullxcorr(  (size(fullxcorr,1)-1)/2-(length(lagvec)-1)/2 : (size(fullxcorr,1)-1)/2+(length(lagvec)-1)/2        );
             autocorr_allout(:,i,tCount)=croppedxcorr;
             autocorr_cum(:,i)=autocorr_cum(:,i)+croppedxcorr;
             tCount=tCount+1;
        end
        
        autocorr_out(:,i)=autocorr_cum(:,i)/length(tWindowVector);

    end
end


%% plot autocorrelations

if plotflag
    figure('Position',[0 0 600 400]);
    hold on; 
    for i=1:numtraces
        size(lagvec)
        size(autocorr_out(:,i))
        plot(lagvec,autocorr_out(:,i),'r');
        %plot(auto(:,i),'r');
    end
    %plot(lagvec,auto_mean,'b');

    title('autocorrelation','fontsize',16,...
             'FontWeight','bold');
    ylabel('corr. coeff');
    xlabel('lag (s)');

    %xlim([-(t_end-t_start)/fs,(t_end-t_start)/fs]);
    ylim([-0.2,1]);
    set(gca,'XTick',[0:8:lagvec(end)]);
end
