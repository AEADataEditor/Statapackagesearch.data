* Preliminaries
* Read in candidatepackages.xlsx (CP)

include "config.do"
*Set working directory here
global rootdir : pwd


* Scan files in subdirectories
	tempfile file_list 
	filelist, directory("$rootdir/Data") pattern("candidatepackages.xlsx")
	gen temp="/"
	egen file_path = concat(dirname temp filename)
	save `file_list'
	keep file_path dirname
	
qui count
	local total_files = `r(N)'
	forvalues i=1/`total_files' {
		local file_`i' = dirname[`i']
		di in red "file_i=file_`i'=`file_`i''"
		
	}

* Read in excel file
forvalues i=1/`total_files' {
	global v = "`file_`i''/candidatepackages.xlsx"
	n di "Reading in file=$v"
	
	*create new dta file for first instance
	
	*tempfile aggCP
		import excel using $v, clear
* Add column with folder name to each candidatepackages.xlsx files and save as dta
        gen dirname="`file_`i''"
		strip dirname, of("$rootdir/Data/") generate(foldername)
		strip foldername, of("aearep-") generate(folderNumbers)
		destring folderNumbers, replace
		local foldernum = folderNumbers[1]


	*Data cleaning

	drop if A =="(Potential) missing package found"
	
	label var A "(Potential) missing package found"
	rename A candidatepkg
	label var B "Package popularity (rank out of total # of packages)"
	rename B pkgpopularity
	label var C "likelihood of false positive based on package popularity"
	rename C probfalsepos
	
	rename D confirm_is_used
	

	destring probfalsepos pkgpopularity confirm_is_used, replace
	
	*If column D is missing (cannot determine if package was used or not), replace with value of 2
	replace confirm_is_used = 2 if missing(confirm_is_used)
    save "`file_`i''/candidatepackages_aearep-`foldernum'.dta", replace


	if `i' == 1 {
		save $rootdir/aggCP.dta, replace
	}
	
	* Append this .dta with each add'l excel file
	else {
		append using $rootdir/aggCP.dta
		save $rootdir/aggCP.dta, replace
	}
	
}



/* Diagnostics */

	use "$rootdir/aggCP.dta", clear


	cap log close
log using $rootdir/summarystats.txt, replace

	*Summary stats
	count if probfalsepos==0
	tab candidatepkg, sort
	tab confirm_is_used
	
	* Most common actual packages
	preserve
	
	drop if confirm_is_used ==2 
	drop if confirm_is_used ==0 
	di as input "Most common packages"
	tab candidatepkg, sort
	
	restore
	
	* Most common false positives
	preserve
	
	drop if confirm_is_used ==2 
	drop if confirm_is_used ==1 
	di as input "Most common false positives"
	tab candidatepkg, sort
	
	restore
	cap log close