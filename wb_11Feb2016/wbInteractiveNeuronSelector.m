function [activeFlags,inPhaseFlags]=wbInteractiveNeuronSelector(neuronList,existingFigureHandle,panelName,alphabetize)

if nargin<3
    alphabetize=true;
end


if nargin<3
    panelName='Neuron Selector';
end

height=20*length(neuronList)+100;
width=120;

if nargin<2 || isempty(existingFigureHandle)
    figure('Position',[600 0 width height],'Name','NeuronSelect Panel');
else
    figure(existingFigureHandle);
end

if alphabetize
    [~,alphaIndex]=sort(neuronList);
else
    alphaIndex=1:length(neuronList);
end


handles=[];
handles.headingText=uicontrol('Style','text','Units','pixel','Position',[5 height-20 width-5 18],'HorizontalAlignment','center','String',panelName);

handles.includeText=uicontrol('Style','text','Units','pixel','Position',[10 height-40 40 20],'HorizontalAlignment','left','String','incl.');
handles.inPhaseText=uicontrol('Style','text','Units','pixel','Position',[30 height-40 40 20],'HorizontalAlignment','left','String','inphase');

for n=1:length(neuronList)
    
    handles.includeCheckbox(n)=uicontrol('Style','checkbox','Units','pixel','Position',[10 height-40-20*n  20 20],'Value',1,'Callback',@(s,e) wbInteractiveNeuronSelectorIncludeCheckboxCallback(n));
    handles.inPhaseCheckbox(n)=uicontrol('Style','checkbox','Units','pixel','Position',[30 height-40-20*n  20 20],'Value',1,'Callback',@(s,e) wbInteractiveNeuronSelectorInPhaseCheckboxCallback(n));
    handles.neuronName(n)=uicontrol('Style','text','Units','pixel','Position',[50 height-40-20*n 60 20],'HorizontalAlignment','left','String',neuronList{alphaIndex(n)},'Callback',@(s,e) wbInteractiveNeuronSelectorNeuronNameCallback);

end

    function wbInteractiveNeuronSelectorIncludeCheckboxCallback(n)
        activeFlags(alphaIndex(n))=get(gcbo,'Value')
    end

    function wbInteractiveNeuronSelectorInPhaseCheckboxCallback(n)
        inPhaseFlags(alphaIndex(n))=get(gcbo,'Value')
    end

    function wbInteractiveNeuronSelectorNeuronNameCallback
        
    end

end
