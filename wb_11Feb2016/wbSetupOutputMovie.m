function videoOutObj=wbSetupOutputMovie(movieOutName,outputMovieQuality,frameRate,size,method)


        if nargin<5
            method='videoutils';  %3rd party library for .mov writing, can write high resolution videos
        else
            method='native';
        end
        
        if nargin<4  %only for videdutils method
            size=[1025 768];
        end
                    
        if nargin<3   %only for native method
            frameRate=20;
        end

        if nargin<2   %only for native method
            outputMovieQuality=100;
        end
        
        
        %create movie object for saving
        
        if strcmp(method,'native')
            
            videoOutObj=VideoWriter(movieOutName,'MPEG-4');
            videoOutObj.FrameRate=frameRate;
            videoOutObj.Quality=outputMovieQuality;
            open(videoOutObj);
        
        else %videoutils
            
            videoOutObj=VideoRecorder(movieOutName,'Format','mov','Size',size);
            
        end
end