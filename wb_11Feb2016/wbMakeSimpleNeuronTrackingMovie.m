function movieOutName=wbMakeSimpleNeuronTrackingMovie(options)

    if nargin<1
        options=[];
    end
    
    options.useSimpleNumbers=true;
    options.showChildrenBlobs=false;

    movieOutName=wbMakeNeuronTrackingMovie([],[],[],[],options);

end