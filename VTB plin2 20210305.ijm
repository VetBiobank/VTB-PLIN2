/* Macro for calculating Area of oilred staining on microscopy Images
 * 
 * Input: Microscopy Images (tif, jpg, png), IHC-stained with green fluoreochrome, counter stained nuclei with DAPI
 * Input: + reference image for full size measurement in green or blue.
 * Process: color deconvolution to seperate green IHC-stain and blue nuclei; 
 * median filter to smooth signal; measure area of stain and nuclei.
 * empirical threshold green stain (PLIN2): [40-255] (optional stop and refine manual threshold).
 * empirical threshold blue stain (DAPI): [30-255] (optional stop and refine manual threshold).
 * Output: Datasheet (xls|csv) with measured values of area. measurements relate to a full size image ROI, implied that te tissues/cells are screen filling.
 * SK / VetBiobank / VetCore / Vetmeduni Vienna 2021
 */

/* Create interactive Window to set variables for 
 * input/output folder, input/output suffix, scale factor, subfolder-processing
 */
#@ String (visibility=MESSAGE, value="Choose your files and parameter", required=false) msg1
#@ File (label = "Input directory", style = "directory") 		input_folder
#@ File (label = "Output directory", style = "directory") 		output_folder
#@ String (label = "File suffix input", description=".mrxs not supported!", choices={".jpg",".png",".tif"}, style="radioButtonHorizontal") 	suffix_in
#@ String (label = "Summary file output") 	output_file
#@ String (label = "Summary file suffix", choices={".xls",".csv"}, style="radioButtonHorizontal") 	suffix_out
#@ String (label = "Blue staining") 	blue_stain
#@ String (label = "Green staining") 	green_stain
#@ Integer (label = "Lower Threshold blue", value=30) 			lower_Thresh_blue
#@ Integer (label = "Upper Threshold blue", value=255) 			upper_Thresh_blue
#@ Integer (label = "Lower Threshold green", value=40) 			lower_Thresh_green
#@ Integer (label = "Upper Threshold green", value=255) 		upper_Thresh_green

#@ String (visibility=MESSAGE, value="Olympus 500µm: 20x = 2715px; 40x = 5430px") msg2
#@ Integer (label = "Scale 500 µm = X Px", value=20) 			scale_px
#@ String (label = "Include subfolders", choices={"no","yes"}, style="radioButtonHorizontal") 		subfolders
#@ String (label = "Stop at Thresholds", choices={"no","yes"}, style="radioButtonHorizontal") 		stopThresh


// prepare and clear logs
run("Set Measurements...", "area mean min integrated limit display redirect=None decimal=1");
newImage("temp", "8-bit white", 1, 1, 1);
run("Measure");
run("Clear Results"); // clear results
print("\\Clear"); // clear log
selectWindow("temp");
run("Close");



processFolder(input_folder);
processSaveResults(output_folder,output_file,suffix_out);



// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input_folder) {
	filelist = getFileList(input_folder);
	filelist = Array.sort(filelist);
	for (i = 0; i < filelist.length; i++) {
		
		// process recursion for subfolders if option "Include subfolders" is true
		if(subfolders=="yes"){
		if(File.isDirectory(input_folder + File.separator + filelist[i]))
			processFolder(input_folder + File.separator + filelist[i]);}
			
		// for images with correct suffix proceed with function processFile()
		if(endsWith(filelist[i], suffix_in))
			processFile(input_folder, output_folder, filelist[i]);
		
		run("Close All");
		run("Collect Garbage");
	}
}


// function to open file, color deconvolute and measure area of oilred channel
function processFile(input_folder, output_folder, file) {

open(input_folder + "\\" + file);

//get title of image and rename jpg for results list
imageTitle = getTitle();
plain_title = getTitle();
plain_title = replace(plain_title, "\\" + suffix_in, "");
             //print("title"+plain_title);

//set scale for image
run("Set Scale...", "distance=" + scale_px + " known=500 unit=µm global");
if (is("composite")) { run("Stack to RGB"); }
imageTitle_RGB = getTitle();
run("Split Channels");
selectWindow(imageTitle_RGB + " (red)");
run("Close");

// Measure blue
selectWindow(imageTitle_RGB + " (blue)");
rename(plain_title + "-"+blue_stain);
run("8-bit");
run("Median...", "radius=10");

// set threshold and create selection
setThreshold(lower_Thresh_blue, upper_Thresh_blue);
run("Threshold...");

if (stopThresh == "yes") {
	title1 = "Set Threshold";
	msg = "Adjust threshold by using the \"Threshold\" sliders\nthen click \"OK\".";
	waitForUser(title1, msg);
}

run("Measure");

//Measure green
selectWindow(imageTitle_RGB + " (green)");
rename(plain_title + "-"+green_stain);
run("8-bit");
run("Median...", "radius=5");

// set threshold and create selection
setThreshold(lower_Thresh_green, upper_Thresh_green);
run("Threshold...");

if (stopThresh == "yes") {
	waitForUser(title1, msg);
}

run("Measure");

}


// function to save results table in predefined output-file
function processSaveResults(output_folder,output_file,suffix_out) {
	selectWindow("Results");
	saveAs("Text", output_folder + "\\"+output_file+suffix_out);
	print("data saved");
}
