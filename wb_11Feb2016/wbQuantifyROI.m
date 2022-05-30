function wbstruct=wbQuantifyROI(folder,neuron,options)
% wbQuantifyROI(wbstruct,neuron,options)
% quantify a new neuron from an existing neuron ROI
%

if nargin<3
    options=[];
end

if ~isfield(options,'offset')
    options.offset=[0 0];
end

if ~isfield(options,'addToWbstruct')
    options.addToWbstruct=true;
end

if ~isfield(options,'useGlobalMovieFlag')
    options.useGlobalMovieFlag=true;
end

if ~isfield(options,'useExistingMask')
    options.useExistingMask=true;
end

[wbstruct, wbstructFileName]=wbload(folder,false);

%load TMIPs
[TMIPMovie,numZ,numTW,validZs]=wbloadTMIPs(folder,wbstruct.metadata);

%get ZMovie from wbstruct info
ZMovie=wbloadmovies(folder,wbstruct.metadata,options.useGlobalMovieFlag);

smoothingTWindow=wbstruct.options.smoothingTWindow;
numPixels=wbstruct.options.numPixels;

%get blobThreads
blobThreads_sorted=wbstruct.blobThreads_sorted;
blobThreads=wbstruct.blobThreads;

Rmax=wbstruct.options.Rmax;
Rbackground=wbstruct.options.Rbackground;

mastermask=uint16(circularmask(wbstruct.options.Rmax));
background.mastermask=uint16(circularmask(Rbackground));        

if strcmp(wbstruct.metadata.noseDirection,'North') || strcmp(wbstruct.metadata.noseDirection,'South')
    width=wbstruct.metadata.fileInfo.width;
    height=wbstruct.metadata.fileInfo.height;
else
    height=wbstruct.metadata.fileInfo.width;
    width=wbstruct.metadata.fileInfo.height;
end
xbound=width;  %size(ZMovie{1},2);  %x and y are reversed in imagedata
ybound=height;  %size(ZMovie{1},1);  %ZMovies are taller than wide

tic
   
this_f_parents=zeros(size(ZMovie{1},3),1);
this_f_background=zeros(size(ZMovie{1},3),1);
this_f_neighbors=zeros(size(ZMovie{1},3),7);
%this_f_neighborbackground(frame,ii)=zeros(size(ZMovie{1},3),7);


for frame=1:size(ZMovie{1},3);

           tw=1 + min([floor((frame-1)/smoothingTWindow) numTW-1]); %which time window are we in?

           for b=wbstruct.neuronlookup(neuron)
                if options.useExistingMask
                    this_mask_nooverlap= wbstruct.mask_nooverlap{tw,blobThreads.parentlist(b)};
                else
                    maskedge_x1=max([1 2+Rmax-(blobThreads_sorted.x(tw,blobThreads.parentlist(b))-options.offset(1))]);
                    maskedge_y1=max([1 2+Rmax-(blobThreads_sorted.y(tw,blobThreads.parentlist(b))-options.offset(2))]);
                    maskedge_x2=min([xbound-(blobThreads_sorted.x(tw,blobThreads.parentlist(b))-options.offset(1))+Rmax+1  2*Rmax+1]);
                    maskedge_y2=min([ybound-(blobThreads_sorted.y(tw,blobThreads.parentlist(b))-options.offset(2))+Rmax+1 2*Rmax+1]);

% ybound
% blobThreads_sorted.y(tw,b)
% options.offset(2)
% Rmax
% maskedge_y1
% maskedge_y2
                    this_mask=mastermask(maskedge_x1:maskedge_x2,maskedge_y1:maskedge_y2);
                    this_mask_nooverlap = this_mask;
                end
           end


           %crop masks overlapping image edge
           for b=1:wbstruct.neuronlookup(neuron)

                %mask coordinates
                background.maskedge_x1=max([1 2+Rbackground-(blobThreads_sorted.x(tw,b)-options.offset(1))]);
                background.maskedge_y1=max([1 2+Rbackground-(blobThreads_sorted.y(tw,b)-options.offset(2))]);
                background.maskedge_x2=min([xbound-(blobThreads_sorted.x(tw,b)-options.offset(1))+Rbackground+1  2*Rbackground+1]);
                background.maskedge_y2=min([ybound-(blobThreads_sorted.y(tw,b)-options.offset(2))+Rbackground+1 2*Rbackground+1]);   

                %absolute image coordinates
                background.ulposx=(blobThreads_sorted.x(tw,b)-options.offset(1))-Rbackground;
                background.ulposy=(blobThreads_sorted.y(tw,b)-options.offset(2))-Rbackground;
                background.dataedge_x1=max([1 background.ulposx]);
                background.dataedge_y1=max([1 background.ulposy]);
                background.dataedge_x2=min([xbound background.ulposx+2*Rbackground]);
                background.dataedge_y2=min([ybound background.ulposy+2*Rbackground]); 

                %blit edge-cropped round mastermask with extracted edge-cropped rectangle from binarized buffer
                %not yet doing blit
%                 background.this_mask=uint16(background.mastermask(background.maskedge_x1:background.maskedge_x2,background.maskedge_y1:background.maskedge_y2)'   .* ...
%                     uint16(MT(background.dataedge_y1:background.dataedge_y2,background.dataedge_x1:background.dataedge_x2,blobThreads_sorted.z(b),tw)==0));
                background.this_mask=uint16(background.mastermask(background.maskedge_x1:background.maskedge_x2,background.maskedge_y1:background.maskedge_y2)');

           end 
      
           
           for b=wbstruct.neuronlookup(neuron)

              ulposx=(blobThreads_sorted.x(tw,blobThreads.parentlist(b))-options.offset(1))-Rmax;
              ulposy=(blobThreads_sorted.y(tw,blobThreads.parentlist(b))- options.offset(2))-Rmax;
              dataedge_x1=max([1 ulposx]);
              dataedge_y1=max([1 ulposy]);
              dataedge_x2=min([xbound ulposx+2*Rmax]);
              dataedge_y2=min([ybound ulposy+2*Rmax]);

              %count pixels within mask 
              cropframe=ZMovie{blobThreads_sorted.z(blobThreads.parentlist(b))}(dataedge_y1:dataedge_y2 ,dataedge_x1:dataedge_x2,frame);

              cropframe_masked=(this_mask_nooverlap').*cropframe;
              allquantpixels=cropframe_masked(:);            

              [vals, ~]=sort(cropframe_masked(:),'descend');  %sort pixels by brightness          
              this_f_parents(frame)=sum(vals(1:numPixels))/numPixels;  %take the mean of the brightest pixels      

              
              %measure neighbor-Z ROIs +/- 3
              ii=1;
              for i= -3:3

                  if blobThreads_sorted.z(blobThreads.parentlist(b)) + i  > 0 && ...
                      blobThreads_sorted.z(blobThreads.parentlist(b)) + i  <= numZ
                  
                      cropframe=ZMovie{blobThreads_sorted.z(blobThreads.parentlist(b)) + i }(dataedge_y1:dataedge_y2 ,dataedge_x1:dataedge_x2,frame);
                      cropframe_masked=(this_mask_nooverlap').*cropframe;
                      allquantpixels=cropframe_masked(:);            

                      [vals, ~]=sort(cropframe_masked(:),'descend');  %sort pixels by brightness       
                      
                      
                      this_f_neighbors(frame,ii)=sum(vals(1:numPixels))/numPixels;  %take the mean of the brightest pixels 

                  else
                      
                      this_f_neighbors(frame,ii)=NaN;
                      
                  end
                  
                  ii=ii+1;
              end
              
              
              %background subtraction,just parent frame for now
              background.ulposx=(blobThreads_sorted.x(tw,blobThreads.parentlist(b))-options.offset(1))-Rbackground;
              background.ulposy=(blobThreads_sorted.y(tw,blobThreads.parentlist(b))-options.offset(2))-Rbackground;
              background.dataedge_x1=max([1 background.ulposx]);
              background.dataedge_y1=max([1 background.ulposy]);
              background.dataedge_x2=min([xbound background.ulposx+2*Rbackground]);
              background.dataedge_y2=min([ybound background.ulposy+2*Rbackground]);

              % count background pixels  NOT YET IMPLEMENTED FOR ADDED NEURONS

%               background.cropframe=ZMovie{blobThreads_sorted.z(blobThreads.parentlist(b))}(background.dataedge_y1:background.dataedge_y2,background.dataedge_x1:background.dataedge_x2,frame);   
%               background.cropframe_masked=background.this_mask.*background.cropframe;          
%               [background.vals, ~]=sort(background.cropframe_masked(:),'descend');  %sort pixels by brightness
%               this_f_background(frame)=sum(background.vals)/length(background.vals);  %take the mean of all background pixels      

              %quantify children+parent  NOT YET IMPLEMENTED FOR ADDED NEURONS

%               for bb=1:length(blobThreads_sorted.children{blobThreads.parentlist(b)}) %quantify multi  
% 
%                    ulposx=blobThreads_sorted.x(tw,blobThreads_sorted.children{blobThreads.parentlist(b)}(bb))-Rmax;
%                    ulposy=blobThreads_sorted.y(tw,blobThreads_sorted.children{blobThreads.parentlist(b)}(bb))-Rmax;
%                    dataedge_x1=max([1 ulposx]);
%                    dataedge_y1=max([1 ulposy]);
%                    dataedge_x2=min([xbound ulposx+2*Rmax]);
%                    dataedge_y2=min([ybound ulposy+2*Rmax]);
% 
%                    cropframechild=ZMovie{blobThreads_sorted.z(blobThreads_sorted.children{blobThreads.parentlist(b)}(bb))}(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,frame);
%                    cropframe_add=(mask_nooverlap{tw,blobThreads_sorted.children{blobThreads.parentlist(b)}(bb)}').*cropframechild;
%                    allquantpixels=[allquantpixels; cropframe_add(:)]; 
% 
%               end
% 
%               [vals, ~]=sort(allquantpixels,'descend');  %sort pixels by brightness
%               numpix=min([length(vals) options.numPixelsBonded]);
%               f_bonded(frame,b)=sum(vals(1:numpix))/numpix;

           end  

           if (mod(frame,500)==0) fprintf('%d..',frame); end

end
      
fprintf('%d.\n',frame);  %print final frame number.
toc
    

%from f_parents to deltaFOverF (not dealing with multi-Z ROIs yet

trace.refNeuron=neuron;
trace.x=blobThreads_sorted.x(:,blobThreads.parentlist(b))-options.offset(1);
trace.y=blobThreads_sorted.y(:,blobThreads.parentlist(b))-options.offset(2);
trace.f0=nanmean(this_f_parents);
trace.deltaFOverFNoBackSub=this_f_parents/trace.f0-1;
trace.deltaFOverF=(this_f_parents-this_f_background)/nanmean(this_f_parents-this_f_background)-1;
trace.neighbors.f0=nanmean(this_f_neighbors);
for i=1:size(this_f_neighbors,2)
    trace.neighbors.deltaFOverF(:,i) = this_f_neighbors(:,i)/trace.neighbors.f0(i)-1;
    trace.neighbors.deltaFOverFNoBackSub(:,i) = this_f_neighbors(:,i)/trace.neighbors.f0(i)-1;
end
    
%add Z planes
trace.neighbors.z=blobThreads_sorted.z(blobThreads.parentlist(wbstruct.neuronlookup(neuron))) + [-3:3];

%added empty picked field
trace.neighbors.picked=[];

%from f_bonded to deltaFOverF
% f0=nanmean(f_bonded(:,neuronlookup(neuron)));
% deltaFOverFNoBackSub=f_bonded(:,neuronlookup(neuron))/f0(neuron)-1;
% deltaFOverF=(f_bonded(:,neuronlookup(neuron))-f_background(:,neuronlookup(neuron)))/nanmean(f_bonded(:,neuronlookup(neuron))-f_background(:,neuronlookup(neuron)))-1;
% 
%     

if options.addToWbstruct
    
    if isfield(wbstruct,'added')
        wbstruct.added.n=wbstruct.added.n+1;
        wbstruct.added.deltaFOverF=[wbstruct.added.deltaFOverF, trace.deltaFOverFNoBackSub];
        wbstruct.added.deltaFOverFNoBackSub=[wbstruct.added.deltaFOverFNoBackSub, trace.deltaFOverFNoBackSub];
        
        wbstruct.added.f0=[wbstruct.added.f0 trace.f0];
        wbstruct.added.dateAdded=[wbstruct.added.dateAdded   datestr(now)];
  
        wbstruct.added.neighbors=[wbstruct.added.neighbors trace.neighbors ];
        
        %old .x string backward compatibiliity
        if size(wbstruct.added.x,1)==1
            wbstruct.added.x=repmat(wbstruct.added.x,length(trace.x) ,1);
            wbstruct.added.y=repmat(wbstruct.added.y,length(trace.y) ,1);
        end
        wbstruct.added.x=[wbstruct.added.x trace.x];
        wbstruct.added.y=[wbstruct.added.y trace.y];        
        wbstruct.added.refNeuron=[wbstruct.added.refNeuron neuron];
    else
        
        wbstruct.added.n=1;
        wbstruct.added.deltaFOverF=trace.deltaFOverF;
        wbstruct.added.deltaFOverFNoBackSub=trace.deltaFOverFNoBackSub;
        wbstruct.added.f0=trace.f0;
        wbstruct.added.dateAdded={datestr(now)};
        wbstruct.added.neighbors=trace.neighbors;
        wbstruct.added.x=trace.x;
        wbstruct.added.y=trace.y;
        wbstruct.added.refNeuron=neuron;

    end
    
    wptoptions.saveFlag=false;
    wbstruct=wbProcessTraces(wbstruct,wptoptions);  %should be more efficient and do this only for one trace
    wbSave(wbstruct,wbstructFileName);

        
end



end