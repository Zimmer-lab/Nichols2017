function metadata=wb

appName='WHOLE BRAIN ANALYZER';
appVersion='1.5';

metafieldExclusions={'dataFolder','editHistory'};
metafileSubfieldExclusions.fileInfo={'numFiles','filenames','widthInFile','heightInFile','numZInFile','numTotalFramesInFile'};

thisDir=pwd;
thisDirShort=[];

figAbsHeight=1000;

handles.thisFigure=figure('Position',[0 0 600 figAbsHeight]);
whitebg([0.3 0.3 0.3]);

%gui layout 

gui.tm=.1; %top margin
gui.lm=.05; %left margin
gui.rm=.05; %right margin

gui.fw=.2; %fieldwidth
gui.in=.04; %indent
gui.lh=.045*.5; %lineheight (relative
gui.mm=.05; %middle margin

annotation('textbox',[0.25 1-gui.tm/1.5 .5 gui.lh],'EdgeColor','none','String',[appName ' ' appVersion],...
           'HorizontalAlignment','center','FontSize',15,'FontWeight','bold','Color','k');

%globals
metafields=[];
wboptions=[];
wboptionsfields=[];
wboptionsfieldExclusions=[];


loadMetaFile;
loadwboptionsFile;
wbstruct=wbload;
renderFields;

%%endmain

%%Subfuncs

    function renderDirectoryGUI
        
       fseps=strfind(thisDir,filesep);
       
       thisDirShort=thisDir(fseps(end)+1:end);
       handles.dirlabel = uicontrol('Style','edit','Units','normalized','Position',[gui.lm+gui.fw (1-gui.tm)     3*gui.fw  gui.lh*0.8],'String',thisDirShort,'Callback',@(s,e) dirEditCallback);
       handles.dirButton = uicontrol('Style','pushbutton','Units','normalized','Position',[gui.lm (1-gui.tm)     gui.fw  gui.lh*0.8],'String','Change DataFolder','BackgroundColor',[.7 .7 .9],'Callback',@(s,e) dirButtonCallback);
       handles.refreshButton = uicontrol('Style','pushbutton','Units','normalized','Position',[1-gui.rm/2-gui.fw 1-gui.tm/2 gui.fw gui.lh*0.8],'String','refresh window','BackgroundColor',[.7 .7 .9],'Callback',@(s,e) refreshButtonCallback);
       
    end
        

    function renderFields
        
       maxOMEFileList=5;
       
       renderDirectoryGUI;

       %metadata COLUMN 1
       annotation('textbox',[gui.lm 1-gui.tm-1.5*gui.lh 2*gui.fw gui.lh],'EdgeColor','none','String','metadata',...
                   'HorizontalAlignment','center','FontSize',12,'FontWeight','bold','Color','w');

       j=1;
       for i=1:length(metafields)

            if ~ismember(metafields{i},metafieldExclusions)
                

                if ~isstruct(getfield(metadata,metafields{i}))
                    
                    handles.fieldLabel(j) = uicontrol('Style','text','Units','normalized','Position',[gui.lm (1-gui.tm)-gui.lh*(j+1) gui.fw  gui.lh*0.77],'String',metafields{i});

                    
                    thisFieldString=num2str(getfield(metadata,metafields{i}));
                    handles.fieldEdit(j) = uicontrol('Style','edit','Units','normalized','Position',[gui.lm+gui.fw (1-gui.tm)-gui.lh*(j+1)  gui.fw  gui.lh*0.8],'String',thisFieldString,'KeyPressFcn',@(s,e) editImmediateCallback(j),'Callback',@(s,e) editCallback(j,i));
                else  %field is a struct
                    
                    handles.fieldLabel(j) = uicontrol('Style','text','Units','normalized','Position',[gui.lm+gui.in (1-gui.tm)-gui.lh*(j+1) gui.fw-gui.in  gui.lh*0.77],'String',metafields{i});

                    annotation('rectangle',[gui.lm (1-gui.tm)-gui.lh*(j+1) gui.in gui.lh*0.8],'FaceColor',[0.2 0.2 0.2],'EdgeColor','none');

                    %hack to add fileInfo regenerate button
                    if strcmp(metafields{i},'fileInfo')
                        handles.fileInfoButton = uicontrol('Style','pushbutton','Units','normalized','Position',[gui.lm+gui.fw+gui.in (1-gui.tm)-gui.lh*(j+1) gui.fw-2*gui.in  gui.lh*0.8],'String','regenerate','BackgroundColor',[.7 .7 .9],'Callback',@(s,e) fileInfoButtonCallback);
                    end
                    
                    
                    structFields=fieldnames(getfield(metadata,metafields{i}));
                    
                    for k=1:length(structFields)  %run through subfields
                        
                        
                        if ~isfield(metafileSubfieldExclusions,metafields{i}) || ~ismember(structFields{k},getfield(metafileSubfieldExclusions,metafields{i}) )
                        
                                j=j+1;

                                fn={metafields{i} structFields{k}};
                                if ~iscell(getfield(metadata,fn{:}))
                                    thisStructFieldString=num2str(getfield(metadata,fn{:}));
                                else
                                    thisStructFieldString=getfield(metadata,fn{:});
                                end
                                handles.fieldLabel(j) = uicontrol('Style','text','Units','normalized','Position',[gui.lm+gui.in (1-gui.tm)-gui.lh*(j+1)     gui.fw-gui.in  gui.lh*0.77],'HorizontalAlignment','left','String',[' ' structFields{k}]);
                                handles.fieldEdit(j) = uicontrol('Style','edit','Units','normalized','Position',[gui.lm+gui.fw (1-gui.tm)-gui.lh*(j+1)     gui.fw  gui.lh*0.8],'String',thisStructFieldString,'KeyPressFcn',@(s,e) editImmediateCallback(j),'Callback',@(s,e) editSubfieldCallback(j,i,fn{:}));
                                annotation('rectangle',[gui.lm (1-gui.tm)-gui.lh*(j+1) gui.in gui.lh*0.8],'FaceColor',MyColor('darkgray'),'EdgeColor','none');

                                drawL(gui.lm,(1-gui.tm)-gui.lh*(j+1),gui.in,gui.lh*0.8,MyColor('gray'));
                        end
                        
                    end
                end

                %handles.hSlider = uicontrol('Style','slider','Position',[20 20 figwidth-30 20],'SliderStep',[1/(ds.numFrames+1) 1/(ds.numFrames+1)],'Value',1/(ds.numFrames+1)); %,'Callback',@(s,e) disp('mouseup')
                j=j+1;
            end
            
       end
       
       %special case: no fileInfo field, so provide button
       if ~strcmp(metafields{i},'fileInfo')
           
             handles.fileInfoButton = uicontrol('Style','pushbutton','Units','normalized','Position',[gui.lm+gui.fw+gui.in (1-gui.tm)-gui.lh*(j+1) gui.fw-2*gui.in  gui.lh*0.8],'String','add fileInfo','BackgroundColor',[.7 .7 .9],'Callback',@(s,e) fileInfoButtonCallback);
  
       end
        
       %display OMEfile list COLUMN 2
       annotation('textbox',[gui.lm+2*gui.fw+gui.mm 1-gui.tm-1.5*gui.lh 2*gui.fw gui.lh],'EdgeColor','none','String','raw datafiles (in order)',...
                   'HorizontalAlignment','center','FontSize',12,'FontWeight','bold','Color','w');
    
       OMEdir=dir('*.ome.tif*');
       OMEFiles=[];
       
       if isempty(OMEdir)
            handles.OMEFileLabel(1) = uicontrol('Style','text','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(2) 2*gui.fw  gui.lh*0.77],'String','No OME files found.  Add some to folder.');
       else
          
           for i=1:length(OMEdir)
                OMEFiles{i}=OMEdir(i).name;
           end
           
           for i=1:min([length(OMEFiles) maxOMEFileList-1])      
                handles.OMEFileLabel(i) = uicontrol('Style','text','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(i+1) 2*gui.fw  gui.lh*0.77],'String',OMEFiles{i});
           end
           
           %don't write the last one if we are maxed out on slots
           if length(OMEFiles)==maxOMEFileList
               handles.OMEFileLabel(maxOMEFileList) = uicontrol('Style','text','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(maxOMEFileList+1) 2*gui.fw  gui.lh*0.77],'String',OMEFiles{maxOMEFileList});   
           elseif length(OMEFiles)>maxOMEFileList
               handles.OMEFileLabel(maxOMEFileList) = uicontrol('Style','text','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(maxOMEFileList+1) 2*gui.fw  gui.lh*0.77],'String','and more...');
           end
           
           %delete old handles if datafile list shrinks in size
           if length(OMEFiles)<maxOMEFileList
               for i=length(OMEFiles)+1:maxOMEFileList
                   if length(handles.OMEFileLabel)>=i && ishghandle(handles.OMEFileLabel(i))
                       delete(handles.OMEFileLabel(i));
                   end 
               end
           end
       end
               
       
       %display Make Montage Movie button
       joffset=maxOMEFileList+1;
       handles.MIPButton = uicontrol('Style','pushbutton','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(joffset)     2*gui.fw  gui.lh*0.8],'String','Make MIP Movie','BackgroundColor',[.7 .7 .9],'Callback',@(s,e) MIPButtonCallback);
        
              
       %display Make MIP Movie button
       joffset=maxOMEFileList+2;
       handles.montageButton = uicontrol('Style','pushbutton','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(joffset)     2*gui.fw  gui.lh*0.8],'String','Make Montage Movie','BackgroundColor',[.7 .7 .9],'Callback',@(s,e) montageButtonCallback);
        
       
       %display wboptions in a white box
       joffset=joffset+1;
       j=1;
       
       annotation('textbox',[gui.lm+2*gui.fw+gui.mm 1-gui.tm-(j+joffset-0.5)*gui.lh 2*gui.fw gui.lh],'EdgeColor','none','String','wboptions',...
                   'HorizontalAlignment','center','FontSize',12,'FontWeight','bold','Color','w');

       for i=1:length(wboptionsfields)

            if ~ismember(wboptionsfields{i},wboptionsfieldExclusions)
                
                handles.wboptionsFieldLabel(j) = uicontrol('Style','text','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(j+joffset)  gui.fw  gui.lh*0.77],'String',wboptionsfields{i});

                thisFieldString=num2str(getfield(wboptions,wboptionsfields{i}));
                handles.wboptionsFieldEdit(j) = uicontrol('Style','edit','Units','normalized','Position',[gui.lm+3*gui.fw+gui.mm (1-gui.tm)-gui.lh*(j+joffset)  gui.fw  gui.lh*0.8],'String',thisFieldString,'KeyPressFcn',@(s,e) wboptionsEditImmediateCallback(j),'Callback',@(s,e) wboptionsEditCallback(j,i));

                j=j+1;
            end
            
       end
       

        
       %tmips
       
       j=j+1;
       annotation('textbox',[gui.lm+2*gui.fw+gui.mm 1-gui.tm-(j+joffset-0.5)*gui.lh 2*gui.fw gui.lh],'EdgeColor','none','String','TMIPs',...
                   'HorizontalAlignment','center','FontSize',12,'FontWeight','bold','Color','w');
       
       if isempty(listfolders('TMIPS'))        
           uicontrol('Style','text','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(j+joffset) 2*gui.fw  gui.lh*0.77],'String','No TMIPs created yet.');
           handles.genTMIPsButton = uicontrol('Style','pushbutton','Units','normalized','Position',[gui.lm+4*gui.fw+gui.mm-gui.fw/2 1-gui.tm-(j+joffset-0.8)*gui.lh gui.fw/2 gui.lh*0.6],'String','create','HorizontalAlignment','right','BackgroundColor',[.7 .7 .9],'Callback',@(s,e) genTMIPsButtonCallback);
       else
           thisString=[num2str(length(listfolders('TMIPS'))) ' Z folders processed.'];
           uicontrol('Style','text','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(j+joffset) 2*gui.fw  gui.lh*0.77],'String',thisString);
           %TMIPS regen button hack
           handles.regenTMIPsButton = uicontrol('Style','pushbutton','Units','normalized','Position',[gui.lm+4*gui.fw+gui.mm-gui.fw/2 1-gui.tm-(j+joffset-0.8)*gui.lh gui.fw/2 gui.lh*0.6],'String','regen','HorizontalAlignment','right','BackgroundColor',[.7 .7 .9],'Callback',@(s,e) regenTMIPsButtonCallback);

       end    

       %blobThreads
       j=j+2;
       annotation('textbox',[gui.lm+2*gui.fw+gui.mm 1-gui.tm-(j+joffset-0.5)*gui.lh 2*gui.fw gui.lh],'EdgeColor','none','String','blobThreads',...
                   'HorizontalAlignment','center','FontSize',12,'FontWeight','bold','Color','w');
       if isempty(wbstruct) || ~isfield(wbstruct,'blobThreads')  
           uicontrol('Style','text','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(j+joffset) 2*gui.fw  gui.lh*0.77],'String','No BlobThreads created yet.');
       else
           thisString=[num2str(size(wbstruct.blobThreads.z,2)) ' blobThreads.'];
           uicontrol('Style','text','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(j+joffset) 2*gui.fw  gui.lh*0.77],'String',thisString);
       end    
       
       %masks
       j=j+2;
       annotation('textbox',[gui.lm+2*gui.fw+gui.mm 1-gui.tm-(j+joffset-0.5)*gui.lh 2*gui.fw gui.lh],'EdgeColor','none','String','Masks',...
                   'HorizontalAlignment','center','FontSize',12,'FontWeight','bold','Color','w');
       if isempty(wbstruct) || ~isfield(wbstruct,'mask')    
           uicontrol('Style','text','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(j+joffset) 2*gui.fw  gui.lh*0.77],'String','No Masks created yet.');
       else
           thisString=[num2str(size(wbstruct.mask,1)) ' masks.'];
           uicontrol('Style','text','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(j+joffset) 2*gui.fw  gui.lh*0.77],'String',thisString);
       end    
       
       %quant 
       j=j+2;
       annotation('textbox',[gui.lm+2*gui.fw+gui.mm 1-gui.tm-(j+joffset-0.5)*gui.lh 2*gui.fw gui.lh],'EdgeColor','none','String','Neurons',...
                   'HorizontalAlignment','center','FontSize',12,'FontWeight','bold','Color','w');
       if isempty(wbstruct) || ~isfield(wbstruct,'deltaFOverF')         
           uicontrol('Style','text','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(j+joffset) 2*gui.fw  gui.lh*0.77],'String','No quantification yet.');
       else
           thisString=[num2str(wbstruct.nn) ' neuron traces.'];
           uicontrol('Style','text','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(j+joffset) 2*gui.fw  gui.lh*0.77],'String',thisString);
       end    
       
       
       %run analysis buttons
       j=j+2;
       if isempty(wbstruct) || ~isfield(wbstruct,'deltaFOverF')         
          thisButtonText='ANALYZE!';
          thisButtonText2='ANALYZE (no movies)';
       else
          thisButtonText='RE-ANALYZE!';

          thisButtonText2='RE-ANALYZE (no movies)';
       end
       
       handles.wbaButton = uicontrol('Style','pushbutton','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(j+joffset-1)     2*gui.fw  gui.lh*0.8],'String',thisButtonText,'BackgroundColor',[.7 .7 .9],'Callback',@(s,e) wbaButtonCallback);
       handles.wbaButton2 = uicontrol('Style','pushbutton','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(j+joffset)     2*gui.fw  gui.lh*0.8],'String',thisButtonText2,'BackgroundColor',[.7 .7 .9],'Callback',@(s,e) wbaButton2Callback);

       
       %right column big rect
       annotation('rectangle',[gui.lm+2*gui.fw+gui.mm/2 1-gui.tm-(1+joffset-0.5)*gui.lh-gui.lh*(j+.2) 2*gui.fw+gui.mm gui.lh*(j+1+.2)]);

              
       %gridplot button
       j=j+2;
       if ~isempty(wbstruct) && isfield(wbstruct,'deltaFOverF')    
           thisButtonText='Grid Plot';
           handles.wbaButton = uicontrol('Style','pushbutton','Units','normalized','Position',[gui.lm+2*gui.fw+gui.mm (1-gui.tm)-gui.lh*(j+joffset)     gui.fw  gui.lh*0.8],'String',thisButtonText,'BackgroundColor',[.7 .7 .9],'Callback',@(s,e) wbGridPlot);
           
           thisButtonText='Heat Plot';
           handles.wbaButton = uicontrol('Style','pushbutton','Units','normalized','Position',[gui.lm+3*gui.fw+gui.mm (1-gui.tm)-gui.lh*(j+joffset)     gui.fw  gui.lh*0.8],'String',thisButtonText,'BackgroundColor',[.7 .7 .9],'Callback',@(s,e) wbHeatPlot);
           
       end
       

       
       
       
    end



    function loadMetaFile
        if exist('meta.mat','file')==2
            metadata=load('meta.mat');
        else
            disp('wb> No meta.mat found.  Creating one from default template.');
            metadata=wbcreatedefaultmetafile;
            metadata.fileInfo=wbaddOMEmetadata;

        end

        metafields=fieldnames(metadata);
    end

    function loadwboptionsFile
        if exist('wboptions.mat','file')==2
            wboptions=load('wboptions.mat');
        else
            disp('wb> No wboptions.mat found.  Creating one from default template.');
            wboptions=wbcreatedefaultwboptionsfile;           
        end

        wboptionsfields=fieldnames(wboptions);
    end

    function drawL(x,y,w,h,thisColor)
        annotation('line',[x+w/2 x+w],[y+h/2 y+h/2],'Color',thisColor); %horiz
        annotation('line',[x+w/2  x+w/2],[y+h/2 y+h],'Color',thisColor); %vert
    end




%%GUI object Callbacks 
    function genTMIPsButtonCallback
        set(handles.genTMIPsButton,'BackgroundColor',color('lr'));
        drawnow;      
        wbOMETMIP(thisDir,wboptions.smoothingTWindow);
        renderFields;
        set(handles.genTMIPsButton,'BackgroundColor',[.7 .7 .9]);          
        
    end

    function regenTMIPsButtonCallback
        set(handles.regenTMIPsButton,'BackgroundColor',color('lr'));
        drawnow;
        wbDeleteTMIPs;
        wbOMETMIP(thisDir,wboptions.smoothingTWindow);
        renderFields;
        set(handles.regenTMIPsButton,'BackgroundColor',[.7 .7 .9]);         
    end

    function fileInfoButtonCallback
        set(handles.fileInfoButton,'BackgroundColor',color('lr'));
        drawnow;
        wbaddOMEmetadata;
        renderFields;
        set(handles.fileInfoButton,'BackgroundColor',[.7 .7 .9]);
    end

    function montageButtonCallback
        set(handles.montageButton,'BackgroundColor',color('lr'));
        drawnow;      
        wbMakeMontageMovie(thisDir);
        figure(handles.thisFigure);
        renderFields;
        set(handles.montageButton,'BackgroundColor',[.7 .7 .9]);      
    end

    function MIPButtonCallback
        set(handles.MIPButton,'BackgroundColor',color('lr'));
        drawnow;      
        wbMakeMIPMovie(thisDir);
        figure(handles.thisFigure);
        renderFields;
        set(handles.MIPButton,'BackgroundColor',[.7 .7 .9]);      
    end


    function wbaButtonCallback
        wba;
        figure(handles.thisFigure);
        renderFields;  %refresh data after running.
    end

    function wbaButton2Callback
        wbaExtraOptions.makeMoviesFlag=false;
        wba([],[],wbaExtraOptions);
        figure(handles.thisFigure);
        renderFields;  %refresh data after running.
    end


    function refreshButtonCallback
        wbstruct=wbload;
        renderFields; 
    end

    function dirButtonCallback
       thisDir = uigetdir('Select directory of log files');
       if thisDir==0
           return;
       end
       cd(thisDir);
       loadMetaFile;
       renderFields;
    end

    function dirEditCallback
        disp('dir');
    end

    function editImmediateCallback(GUIfieldNum)
        set(handles.fieldEdit(GUIfieldNum),'BackgroundColor',color('lr'));
    end

    function editCallback(GUIfieldNum,metafieldNum)
        newVal=get(gcbo,'String');
        if ~isempty (str2num(newVal)) %numerical field
            metadata=setfield(metadata,metafields{metafieldNum},str2num(newVal));
        else %non-numerical field
            metadata=setfield(metadata,metafields{metafieldNum},get(gcbo,'String'));
        end
        save('meta.mat','-struct','metadata'); 
        set(handles.fieldEdit(GUIfieldNum),'BackgroundColor','w');       
    end

    function editSubfieldCallback(GUIfieldNum,metafieldNum,globalfieldname,globalsubfieldname)
        newVal=get(gcbo,'String');
        fn={globalfieldname,globalsubfieldname};
        if ~isempty (str2num(newVal)) %numerical field       
            metadata=setfield(metadata,fn{:} ,str2num(newVal));
        else %non-numerical
            metadata=setfield(metadata,fn{:},get(gcbo,'String'));
        end
        save('meta.mat','-struct','metadata'); 
        set(handles.fieldEdit(GUIfieldNum),'BackgroundColor','w');       
    end

    function wboptionsEditImmediateCallback(GUIfieldNum)
        set(handles.wboptionsFieldEdit(GUIfieldNum),'BackgroundColor',color('lr'));
    end

    function wboptionsEditCallback(GUIfieldNum,wboptionsfieldNum)
        newVal=get(gcbo,'String');
        if ~isempty (str2num(newVal)) 
            wboptions=setfield(wboptions,wboptionsfields{wboptionsfieldNum},str2num(newVal));
        else
            wboptions=setfield(wboptions,wboptionsfields{wboptionsfieldNum},get(gcbo,'String'));
        end
        save('wboptions.mat','-struct','wboptions'); 
        set(handles.wboptionsFieldEdit(GUIfieldNum),'BackgroundColor','w');       
    end


end