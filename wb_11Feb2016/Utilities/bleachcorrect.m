function [traces_bc,suppData] = bleachcorrect(traces,options)

%,endrange,method,coop,startrange,fminfac,looseparam)
%
%[traces_bc,tau,bleachcurves] = bleachcorrect(traces,endrange,method,coop,startrange,fminfac)
%
%bleach correct an array of traces based on ending baseline value

%Saul Kato

if nargin<2
    options=[];
end

if ~isfield(options,'baselineMethod')
    options.baselineMethod='min';
end

if ~isfield(options,'looseness')
    options.looseness=0.1;
end

if ~isfield(options,'method')
    options.method='exprelax';
end

if ~isfield(options,'fminfac')
    options.fminfac=0.9;
end

if ~isfield(options,'startFrames')
    options.startFrames=100;
end

if ~isfield(options,'endFrames')
    options.endFrames=100;
end

if ~isfield(options,'coop')
    options.coop=0;
end

if ~isfield(options,'startRange')
    options.startRange=[1 options.startFrames];
    disp('bleachcorrect> startRange autoselected.');
end

if ~isfield(options,'endRange')
    options.endRange=[size(traces,1)-options.endFrames+1 size(traces,1)];
    disp('bleachcorrect> endRange autoselected.');
end


traces_bc=zeros(size(traces));

if strcmp(options.method,'linear') || strcmp(options.method,'lin')

    for i=1:size(traces,2)
       bleach_start(i)=mean(traces(options.startRange(1):options.startRange(2),i));
       
       bleach_end(i)=mean(traces(options.endRange(1):options.endRange(2),i));  %pick end area to avg
       
       if isnan(mean(traces(options.endRange(1):options.endRange(2),i)))  disp('nan detect'); break; end
       
       startframe=options.startRange(1);
       endframe=options.endRange(2);
       
       
       if options.coop==0
           
          traces_bc(:,i)=traces(:,i)-(0:size(traces,1)-1)'*(bleach_end(i)-bleach_start(i))/(size(traces,1)-1);
          
       else
           
          tmax=(endframe-startframe);
          alpha=(1-bleach_end(i)/bleach_start(i))/tmax;
          tvec=(0:endframe-startframe)';
          traces_bc(startframe:endframe,i)=((traces(startframe:endframe,i)-options.fminfac*(1-alpha*tvec)*bleach_start(i))./(1-alpha*tvec)).^(1/options.coop);

       end
       
    end
    tau=zeros(size(traces,2),1);
    
elseif strcmp(options.method,'expo') || strcmp(options.method,'exp') %exponential curve relaxation method
    
    inp=(1:size(traces,1))';
    tf=mean(options.endRange);   
    
    
    ti=mean(options.startRange);
    tau=1./linspace(1/(2*(tf-ti)),1/(.1*(tf-ti)),200);
    
    for i=1:size(traces,2)
        yf=min(traces(:,i));
       % yi=mean(traces(options.startRange(1):options.startRange(2),i)); 
       
        if strcmp(options.baselineMethod,'min')
            [yi ti]=min(traces(options.startRange(1):options.startRange(2),i));   
        else
            yi=mean(traces(options.startRange(1):options.startRange(2),i));
        end

        intersect=1;
        j=1;
        
        while intersect==1 && j<101;
            ex=exp(-(tf-ti)/tau(j));
            k=(yf-yi*ex)/(1-ex);
            bleachcurves(:,i)=(yi-k)*exp(-inp/tau(j))+k;
            tr=[options.startRange(2)+200 (options.endRange(1)-1000)];
            if isempty(find(traces(tr(1):tr(2),i)-bleachcurves(tr(1):tr(2),i)<0, 1))
              intersect=0;
            end
            j=j+1;
        end
        
        tau_best(i)=tau(j-1);
         

        bleachcurves(:,i)=(yi-k)*exp(-inp/tau_best(i))+k;       
        
        traces_bc(:,i)=traces(:,i)-bleachcurves(:,i);
    end  
    tau=tau_best;
    
    
elseif strcmp(options.method,'exp2')  %new exponential zero offset with gain correction 8/20/12
    inp=(1:size(traces,1))';
  
    ti=options.startRange(2);
    tf=options.endRange(1);  
    
    tmax=(tf-ti);
    
    for i=1:size(traces,2)
        
        yf=mean(traces(options.endRange(1):options.endRange(2),i));
        yi=mean(traces(options.startRange(1):options.startRange(2),i)); 
        tau(i)=(tf-ti)/log(yi/yf);
        amp(i)=yi*exp(ti/tau(i));
        bleachcurves(:,i)=amp(i)*exp(-inp/tau(i));
        alphat=exp(-((0:(tf-ti))'/tau(i)));

        coopa=options.coop; if (coopa==0) coopa=1; end
        
        traces_bc(ti:tf,i)=((traces(ti:tf,i)-options.fminfac*(alphat)*yi)./(alphat)).^(1/coopa);

        traces_bc(tf+1:end,i)=traces_bc(tf,i);
        traces_bc(1:ti-1,i)=traces(1:ti-1,i)-traces(ti,i)+traces_bc(ti,i);
   
    end
    


else  %exprelax: loose exponential curve relaxation
    
    
    inp=(1:size(traces,1))';
    tf=mean(options.endRange);   
    ti=mean(options.startRange);
    tau=1./linspace(1/(2*(tf-ti)),1/(.1*(tf-ti)),200);
    
    for i=1:size(traces,2)
        yf=min(traces(:,i));
        yi=mean(traces(options.startRange(1):options.startRange(2),i)); 
        intersect=1;
        j=1;
        while intersect==1 && j<101;
            ex=exp(-(tf-ti)/tau(j));
            k=(yf-yi*ex)/(1-ex);
            bleachcurves(:,i)=(yi-k)*exp(-inp/tau(j))+k;
            tr=[options.startRange(2)+200 (options.endRange(1)-1000)];
            if isempty(find(traces(tr(1):tr(2),i)-bleachcurves(tr(1):tr(2),i) < - options.looseness, 1))
              intersect=0;
            end
            j=j+1;
        end
        
        tau_best(i)=tau(j-1);
        bleachcurves(:,i)=(yi-k)*exp(-inp/tau_best(i))+k;
       
        
        traces_bc(:,i)=traces(:,i)-bleachcurves(:,i);
    end
    
    tau=tau_best;
    
end


suppData.tau=tau;
if exist('bleachcurves','var')
    suppData.bleachcurves=bleachcurves;
end

end