*! strip.ado	4/9/1997 by P.T.Seed (p.seed@umds.ac.uk)
*! version 1.00
*! usage: strip <var>, of("<character string>") Generate(<newvar>)

prog define strip
	local varlist "req ex min(1) max(1)"
	local options "of(str) Generate(str)"
	parse "`*'"

	local var "`varlist'"
	local newvar `generate'

	tempvar length
	qui gen `length' = length(`var')
	qui summ `length'
	local lmax = _result(6)
	qui gen str`lmax' `newvar' = `var'
	local i = 1
	while `i' <= length("`of'") {
*		di "local char = substr(`of',`i',1)"
		local char = substr("`of'",`i',1)
*		di "cap assert index(`newvar',|`char'|) == 0"
		cap assert index(`newvar',"`char'") == 0
		while _rc {
*			di "qui replace `newvar' =substr(`newvar',1,index(`newvar',|`char'|)-1)+ substr( `newvar',index(`newvar',|`char'|)+1,.)"
			qui replace `newvar' =substr(`newvar',1,index(`newvar',"`char'")-1) +substr(`newvar',index(`newvar',"`char'")+1,.)
*			di "cap assert index(`newvar',|`char'|) == 0"
			cap assert index(`newvar',"`char'") == 0
			}
		local i = `i' + 1
		}
end strip 
exit
