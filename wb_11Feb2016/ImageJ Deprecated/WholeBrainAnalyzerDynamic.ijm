macro "Der Whole Brain Analyzer Dynamic Action Tool - B1dCc00T0012WTa012B "  { 
// File.copy requires ImageJ 1.47j
print("\\Clear");  // clear log window
print("Running Der Whole Brain Analyzer *Dynamic*.");


dir = getDirectory("Choose a Data Directory to Analyze");
File.makeDirectory(dir+"SmoothStabZMovies"); 
print(dir);

numZ=10;

//get crop coords
if (File.exists(dir+"Overviews/globalCoords.txt"))
{
      print(">[2/5] found globalCoords.txt. Loading cropping and orientation information.");
	  filestring=File.openAsString(dir+"Overviews/globalCoords.txt"); 
	  vals=split(filestring); 
      x=parseInt(vals[0]);
	  y=parseInt(vals[1]);
      w=parseInt(vals[2]);
	  h=parseInt(vals[3]);
	  AVQuadrant=parseInt(vals[4]);
      print("Read selection bounds: "+x+" "+y+" "+w+" "+h+", Anterio-ventral Quadrant="+AVQuadrant);
}

//create paddedZ for folder and filenames
maxZchars=lengthOf(toString(numZ));
destDir=newArray(numZ);
paddedZ=newArray(numZ);
for (z=0; z<numZ; z++) {
	padding="000";  //assumes that there are no more than 999 Z planes, easy to fix
	paddedZ[z]=padding+toString(z+1);
	paddedZ[z]=substring(paddedZ[z],lengthOf(paddedZ[z])-maxZchars,lengthOf(paddedZ[z]));
	destDir[z]=dir+"TMIPS-Z"+paddedZ[z];
}


for (z=0;z<numZ;z++) {

	print(paddedZ[z]);
     //load and crop Z movie
	run("Image Sequence...", "open=["+dir+"Originals] starting=1 increment=1 scale=100 file=Z0"+paddedZ[z]+" sort use");
	getDimensions(width, height, channels, numT, numZnotcorrect);
	makeRectangle(x,y,w,h);
	run("Crop");
	
	//create paddedT for filenames
	maxTchars=lengthOf(toString(numT));
	paddedT=newArray(numT);
	for (t=0; t<numT; t++) {
		padding="0000";  //assumes that there are no more than 999 Z planes, easy to fix if necessary
		paddedT[t]=padding+toString(t+1);
		paddedT[t]=substring(paddedT[t],lengthOf(paddedT[t])-maxTchars,lengthOf(paddedT[t]));
	}

	//generate and save TMIPs
	File.makeDirectory(destDir[z]); 
	for (t=0; t<numT; t=t+100) {
		t99=t+99;
		run("Z Project...", "start="+t+" stop="+t99+" projection=[Average Intensity]");
		saveAs("Tiff", destDir[z]+"/TMIP-"+paddedZ[z]+"T"+paddedT[t]+".tif");
		close();
	}
	
	//image stabilize TMIP folder
	File.makeDirectory(destDir[z]+"Stab"); 
	run("Image Sequence...", "open=["+destDir[z]+"] starting=1 increment=1 scale=100 sort");	
	//run("StackReg", "transformation=[Translation]");
	//run("Image Stabilizer", "transformation=Translation maximum_pyramid_levels=1 template_update_coefficient=0.90 maximum_iterations=200 error_tolerance=0.0000001 log_transformation_coefficients output_to_a_new_stack");
	run("MultiStackRegSaul ", "stack_1=TMIPS-Z"+paddedZ[z]+" action_1=Align file_1=[] stack_2=None action_2=Ignore file_2=[] transformation=Translation save");
	
	saveAs("Tiff", dir+"SmoothStabZMovies/SmoothStabMovie_Z"+paddedZ[z]+".tif");	
	close();	

}

}

/*

//run("Bio-Formats", " color_mode=Default display_metadata display_ome-xml view=Hyperstack stack_order=XYCZT");
//run("Bio-Formats Importer", " color_mode=Default display_ome-xml view=Hyperstack stack_order=XYCZT use_virtual_stack");
run("Bio-Formats Importer", " color_mode=Default view=Hyperstack stack_order=XYCZT");
dir=getDirectory("image");
omefilename=getTitle();
getDimensions(width, height, channels, numZ, numT);

print("File loaded: " + omefilename);
print("File has "+numZ+" Z slices and "+numT+" time points.");

if (File.exists(dir+"Overviews/MIPall-uncropped.tif"))
{
    print(">[1/6] found MIPall-uncropped.");

}
else
{
   //do an MIP on the whole dataset to facilitate cropping of the whole dataset
   print(">[1/5] Generating Maximum Intensity Projection on whole dataset.");
   run("Z Project...", "start=1 projection=[Max Intensity] all");  //across T
   run("Z Project...", "start=1 projection=[Max Intensity]");  //acrossZ
   
   File.makeDirectory(dir+"Overviews"); 
   saveAs("Tiff", dir+"Overviews/MIPall-uncropped.tif");
}

run("Red Hot");
run("Brightness/Contrast...");

if (File.exists(dir+"Overviews/globalCoords.txt"))
{
      print(">[2/5] found globalCoords.txt. Loading cropping and orientation information.");
	  filestring=File.openAsString(dir+"Overviews/globalCoords.txt"); 
	  vals=split(filestring); 
      x=parseInt(vals[0]);
	  y=parseInt(vals[1]);
      w=parseInt(vals[2]);
	  h=parseInt(vals[3]);
	  AVQuadrant=parseInt(vals[4]);
      print("Read selection bounds: "+x+" "+y+" "+w+" "+h+", Anterio-ventral Quadrant="+AVQuadrant);
}

else
{
    open(dir+"Overviews/MIPall-uncropped.tif");
	run("Red Hot");
	run("Brightness/Contrast...");
	setTool("rectangle");
	showStatus("Draw the smallest crop box containing all activity and press space bar.");
	beep();
	print(">[2/5] USER ACTION NEEDED> Draw the smallest crop box containing all action and PRESS SPACE BAR.");
	do {
		// Measure selection parameters.
		getSelectionBounds(x, y, w, h);
		wait(100);
	} while (isKeyDown("space") != 1);
    print("Selection bounds: "+x+" "+y+" "+w+" "+h);
	if  (selectionType() == -1) 
	    print(">No region drawn.  Using entire image.");
	else
	{
	    run("Crop");
	}
	
	//request anterioventral corner
	setTool("point");
	showStatus("Click somewhere in the anterio-ventral quadrant.");
	beep();
	print(">[2.5/5] USER ACTION NEEDED> Click somewhere in the anterio-ventral quadrant.");
	leftButton=16;
	do {
		// Measure selection parameters.
		getCursorLoc(xCursor, yCursor, zCursor, flagsCursor);
		if (xCursor<= width/2)
		{
			if  (yCursor<= height/2) AVQuadrant=1;
			else AVQuadrant=4;
		}
		else 
		{
			if (yCursor<= height/2) AVQuadrant=2;
			else AVQuadrant=3;	
		}	
		showStatus("Anterio-Ventral Quadrant = "+AVQuadrant);
		
		wait(10);
		
	} while (flagsCursor&leftButton==0);

		
	//rotate and flip image if necessary
	print('Transforming to anterior-up + ventral-left orientation.');
	if (getWidth() > getHeight())   //horizontal
	{
		if (AVQuadrant==1)
			{
			run("Rotate 90 Degrees Right");
			run("Flip Horizontally");	
		    }				
	    else if (AVQuadrant==2)
			run("Rotate 90 Degrees Left");
		else if  (AVQuadrant==3)
			{
			run("Rotate 90 Degrees Right");
			run("Flip Vertically");
			}
		else //4
			run("Rotate 90 Degrees Right");
	}
	else  //already vertical
	{
		//if AVQuadrant 1 it is already in correct position
		if  (AVQuadrant==2)
			run("Flip Horizontally");	
		else if  (AVQuadrant==3)
			{
			run("Rotate 90 Degrees Right");
			run("Rotate 90 Degrees Right");
			}
		else if (AVQuadrant==4)
			run("Flip Vertically");
		
	}
	
	//save out MIPall and global coordinates
	saveAs("Tiff", dir+"Overviews/MIPall.tif");
	f = File.open(dir+"Overviews/globalCoords.txt");
	print(f,x+" "+y+" "+w+" "+h+" "+AVQuadrant); 
	File.close(f);
}

//crop and rotate/reflect hyperstack
print(">[3/5] Cropping and rotating/reflecting hyperstack.");
selectWindow(omefilename);
makeRectangle(x,y,w,h);
run("Crop");

if (x > y)   //horizontal
{
		if (AVQuadrant==1)
			{
			run("Rotate 90 Degrees Right");
			run("Flip Horizontally","stack");	
		    }				
	    else if (AVQuadrant==2)
			run("Rotate 90 Degrees Left");
		else if  (AVQuadrant==3)
			{
			run("Rotate 90 Degrees Right");
			run("Flip Vertically","stack");
			}
		else //4
			run("Rotate 90 Degrees Right");
}
else  //already vertical
{
		//if AVQuadrant 1 it is already in correct position
		if  (AVQuadrant==2)
			run("Flip Horizontally","stack");	
		else if  (AVQuadrant==3)
			{
			run("Rotate 90 Degrees Right");
			run("Rotate 90 Degrees Right");
			}
		else if (AVQuadrant==4)
			run("Flip Vertically","stack");
		
}


print(">[4/5] Creating image-stabilized Z-movies and ZMIPs.");

File.makeDirectory(dir+"StabilizedZMovies"); 
File.makeDirectory(dir+"ZMIPs"); 

//created paddedZ for filenames
maxZchars=lengthOf(toString(numZ));
paddedZ=newArray(numZ);
for (z=0; z<numZ; z++) {
	padding="000";  //assumes that there are no more than 999 Z planes, easy to fix if necessary
	paddedZ[z]=padding+toString(z+1);
	paddedZ[z]=substring(paddedZ[z],lengthOf(paddedZ[z])-maxZchars,lengthOf(paddedZ[z]));
}

//Stabilize and save Z movies
print("processing...1/"+numZ);
for (z=0; z<numZ; z++)
{
	ZMovieIsOpen=0;
	zplus1=z+1;
	print("\\Update:processing..."+zplus1+"/"+numZ);
	
	if (File.exists(dir+"StabilizedZMovies/Stabilized_Z"+paddedZ[z]+".tif"))
	    print("Stabilized_Z"+paddedZ[z]+".tif already exists. Skipping.");
	else
	{
		selectWindow(omefilename);
		run("Make Substack...", "slices="+zplus1+" frames=1-"+numT);
		run("Red Hot");	
		run("StackReg", "transformation=[Rigid Body]");
		
		
	    ZMovieIsOpen=1;
		//save individual z-stack
		saveAs("Tiff", dir+"StabilizedZMovies/Stabilized_Z"+paddedZ[z]+".tif");
    }
	
	if (File.exists( dir+"/ZMIPs/MED_Stabilized_Z"+paddedZ[z]+".tif"))
	{
	   print("MED_Stabilized_Z"+paddedZ[z]+".tif already exists. Skipping.");
	   print("");
    }
	else
	{
		//create median intensity projection for each Z movie and then close it.
		run("Z Project...", "projection=Median");
		saveAs("Tiff", dir+"/ZMIPs/MED_Stabilized_Z"+paddedZ[z]+".tif");
	    close();		
    }
	
	//close z-movie if opened
	if (ZMovieIsOpen) close();
}

print(">[5/5] Generating overviews.");
run("Image Sequence...", "open=["+dir+"/ZMIPs] starting=1 increment=1 scale=100 file=[] sort");
run("Z Project...", "projection=[Max Intensity]");
saveAs("Tiff", dir+"Overviews/MIPall_Stabilized.tif");
close();
run("Make Montage...", "columns="+numZ+" rows=1 scale=1 increment=1 border=0 font=12 label");  //good for tall narrow
saveAs("Tiff", dir+"Overviews/MIPMontage_Stabilized.tif");


print(">FIN.");

}  //END MACRO


//OME converter that preserves Z/T information (image sequence to OME hyperstack)
macro "Convert to OME Action Tool - B0cC090T0010OT6010MTe010E"  { 

print("\\Clear");  // clear log window
print("Running Convert to OME.");

dir = getDirectory("Choose a Directory to Convert");
print(dir);
list = getFileList(dir);

//exclude non .tif files
k=0;
newlist = newArray(list.length);
for (i=0; i < list.length; i++)  {
	if (endsWith(list[i], ".tif")) {
	newlist[k] = list[i];
	k=k+1;
	}
}
dirOriginals=dir;

list = Array.trim(newlist, k);
if (list.length==0) {
    print(">No .tifs found in this directory. Checking for Originals subfolder.");
    list = getFileList(dir+"/Originals");
    dirOriginals=dir+"/Originals";
    //exclude non .tif files
    k=0;
    newlist = newArray(list.length);
    for (i=0; i < list.length; i++)  {
	  if (endsWith(list[i], ".tif")) {
 	  newlist[k] = list[i];
 	  k=k+1;
 	  }
    }  
    if (list.length==0)  {
      print("Quitting.");
      exit;
    }
    list = Array.trim(newlist, k);
}


//find highest Z slice and T index and check for correct number of files
Zmax=0;
Tmax=0;
Znum=newArray(list.length);
Tnum=newArray(list.length);

for (i=0; i < list.length; i++)  {
	//print(list[i]);
	//find the next non-numerical character after Z. indexOf does not support wildcards/regular expressions.  in future use matches().
	letterZpos=indexOf(list[i],"Z");
	letterTpos=indexOf(list[i],"T",letterZpos);
	if (letterTpos==-1) letterTpos=list.length;	
	letterCpos=indexOf(list[i],"C",letterZpos);
	if (letterCpos==-1) letterCpos=list.length;	
	letter_pos=indexOf(list[i],"_",letterZpos);
	if (letter_pos==-1) letter_pos=list.length;
	letterDotTifpos=indexOf(list[i],".tif",letterZpos);
	endZnumpos=minOf(letterTpos,minOf(letterCpos,minOf(letter_pos,letterDotTifpos)));
	Znum[i]=substring(list[i],letterZpos+1,endZnumpos);
	if (parseInt(Znum[i])>parseInt(Zmax)) {
		Zmax=Znum[i];
	}
	//find the next non-numerical character after T. indexOf does not support wildcards/regular expressions.  in future use matches().
	letterTpos=indexOf(list[i],"T");	
	letterCpos=indexOf(list[i],"C",letterTpos);
	if (letterCpos==-1) letterCpos=list.length;		
	letterZpos=indexOf(list[i],"Z",letterTpos);
	if (letterZpos==-1) letterZpos=list.length;			
	letter_pos=indexOf(list[i],"_",letterTpos);
	if (letter_pos==-1) letter_pos=list.length;			
	letterDotpos=indexOf(list[i],".",letterTpos);	
	endTnumpos=minOf(letterCpos,minOf(letterZpos,minOf(letter_pos,letterDotpos)));
	Tnum[i]=substring(list[i],letterTpos+1,endTnumpos);
	if (parseInt(Tnum[i])>parseInt(Tmax)) {
		Tmax=Tnum[i];
	}	
}
Tnumcharlength=endTnumpos-letterTpos;
Zmax=parseInt(Zmax);
Tmax=parseInt(Tmax);
print(">Max Z-slice found is "+Zmax+".");
print(">Max T-frame found is "+Tmax+".");
tifnumChecksum=Zmax*Tmax;

if (tifnumChecksum==list.length)
	print(">Total # of .tifs ("+list.length+") is consistent.  Converting to OME.");
else
{
	print(">Total # of .tifs ("+list.length+") is inconsistent. A future version of this software might deal with this. Quitting.");
	exit;
}

run("Image Sequence...", "open=["+dirOriginals+"] starting=1 increment=1 scale=100 file=.tif sort use");
imageFilename = getTitle; 
//dotIndex = indexOf(imageFilename, "."); 
//titleNoExtension = substring(imageFilename, 0, dotIndex);
run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices="+Zmax+" frames="+Tmax+" display=Color");
run("Bio-Formats Exporter", "save=["+dirOriginals+imageFilename+".ome.tif] compression=LZW");

print("FIN.");
}
*/
