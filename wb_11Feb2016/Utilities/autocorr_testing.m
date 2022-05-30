%autocorr_testing

avfl=wbgettrace('AVFR');
figure;
maxlag=50;
nc=3; 
centerTimeVector=1+maxlag:maxlag:length(avfl)-maxlag;
tCount=1;
for t=centerTimeVector
    
    scrollsubplot(10,nc,nc*tCount-1);
    plot((t-maxlag:t+maxlag)/wbstruct.fps,avfl(t-maxlag:t+maxlag));
    
    scrollsubplot(10,nc,nc*tCount-2);
    
    xc(:,t)=xcorr(detrend(avfl(t-maxlag:t+maxlag),'linear'),'coeff');
    plot(mtv(xc(:,t),1/wbstruct.fps)-size(xc,1)/wbstruct.fps/2,xc(:,t));
    tCount=tCount+1;
    
    xlim([-maxlag maxlag]/wbstruct.fps);
    
    set(gca,'XTick',-10:2:10);
    
end

figure;
plot(mtv(mean(xc,2),1/wbstruct.fps)-size(xc,1)/wbstruct.fps/2,mean(xc(:,:),2));
set(gca,'XTick',-10:2:10);