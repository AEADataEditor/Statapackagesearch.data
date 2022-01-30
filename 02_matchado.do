clear all

* Preliminaries
include "config.do"

* Set this to the corresponding domain that these files are created for
global domain "econ"

* Data Cleaning master csv file	
	
import delimited "${rootdir}/Data/count_all.csv", clear

drop v4-nextup370
drop if key != "adofile"

replace value = substr(value,1,strlen(value)-4)
strip value, of("_") generate(cleaned_value)

replace value = cleaned_value
drop cleaned_value
rename value candidatepkg


* Cleaning individual xlsx files

strip aearep, of("aearep-") generate(folderNumbers)
destring folderNumbers, replace

levelsof folderNumbers, local(levels)

save $rootdir/matchado.dta, replace



* cross refer

tempfile matchresults


foreach v of local levels {
	
	n di "currently running `v'"
	
	capture confirm file $rootdir/Data/aearep-`v'/candidatepackages_aearep-`v'.dta
if !_rc {
	* do something if the file exists

	
	use "$rootdir/matchado.dta"
	drop if folderNumbers != `v'
	drop aearep key
	
	* rm duplicates
	sort candidatepkg
	by candidatepkg:  gen dup = cond(_N==1,0,_n)
	drop if dup>1
	
	tempfile subset
	save `subset'
	
	
	sort candidatepkg
		merge 1:1 candidatepkg using $rootdir/Data/aearep-`v'/candidatepackages_aearep-`v'.dta
	
	keep if _merge==3
	keep candidatepkg
	
	cap append using `matchresults'
	save `matchresults', replace
	
	/*
	cap sort candidatepkg
	if _rc ==0 {
	merge 1:1 candidatepkg using $rootdir/Data/aearep-`1'/candidatepackages_aearep-`1'.dta
	
	list if _merge==3
	*/
	}
	
	else {
		di "no candidatepackages.xlsx generated for this issue"
	}
	
}
	/* save final file */
	use `matchresults', clear
	
	*Cleaning- collapse into unique packages and count of observations
	gen uniquepkgs = candidatepkg
	sort uniquepkgs
	qui by uniquepkgs : gen dup = cond(_N==1,0,_n)
	replace uniquepkgs="." if dup>1
	
	egen frequency = count(uniquepkgs), by(candidatepkg)
	drop if dup>1
	drop dup uniquepkgs
	
	gsort -frequency
    rename candidatepkg packagename
    rename frequency hits
    gen rank = _n
    order rank hits packagename

	
	save "$rootdir/p_stats_${domain}.dta", replace

	
	
	* whatshot vs results for packagesearch.ado file- allow toggle (required option?)- way to switch between
	* then run basic tests- should have stronger suggestion of true packages with less false positives
	
	* name it something that indicates it;s from econ (want to be able to add other disciplines)
	*final file will have package, frequency, field ("econ")
	* may miss things (b/c not using whatshot) - that's OK
		*long term goal- blend of the two (weighted average)
		
		*have matchresults as an ancillary file that gets pulled from github

