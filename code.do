//// Stacking
use "C:\Users\21242\Desktop\数据\data0220.dta", replace
g never_treated=1 if policy_year==.
replace never_treated=0 if never_treated==.
egen max_treat= max(KZC), by(ID)
keep if policy_year >= 2012
levelsof policy_year if never_treated == 0 ,local(slist)
save stacking_raw1C, replace 
use  stacking_raw1C, clear
levelsof policy_year if never_treated == 0 ,local(slist)
foreach var of local slist  {
	display `var'
	use  stacking_raw1C, clear 
	gen group_id = `var'
	
	* keep the treated State_ID and never treated states 
	keep if (policy_year == `var' | never_treated == 1)
	
	* get the effective Yearfor the treated State_ID
	gen id_year_temp = policy_year if policy_year == `var' 
	egen id_year = max(id_year_temp)
	
	* keep 5 years pre-period and 5 years post-period
	keep if year <= (id_year+ 3) 
	keep if year >= (id_year- 3)

	save stacking_raw1C_`var', replace
}
use  "stacking_raw1C_2012.dta",clear
ap using "stacking_raw1C_2013.dta"
ap using "stacking_raw1C_2014.dta"
ap using "stacking_raw1C_2016.dta"
ap using "stacking_raw1C_2018.dta"
ap using "stacking_raw1C_2019.dta"
ap using "stacking_raw1C_2020.dta"
ap using "stacking_raw1C_2021.dta"
ap using "stacking_raw1C_2022.dta"
gen time_to_treat = year -policy_year
tab time_to_treat,missing
*Def------------------------
global Before_TP "3"
global Post_TP "3"
*----------------------------
*Post_0=Current
*Pre* Post* 
forvalues i= $Before_TP (-1)1{
	g Pre_`i'=(time_to_treat+`i'==0)
}

forvalues i=0/ $Post_TP {
	g Post_`i'=(time_to_treat-`i'==0)
}

*Pres* Posts* 
forvalues i= $Before_TP (-1)3{
	g Pres_`i'=(time_to_treat+`i'<=0)
}

forvalues i=2/ $Post_TP {
	g Posts_`i'=(time_to_treat-`i'>=0)
	replace Posts_`i' =0 if time_to_treat ==.
}
save "C:\Users\21242\Desktop\数据 处理 文本\数据.dta", replace
//Main return
use "C:\Users\21242\Desktop\数据 处理 文本\数据.dta"
reghdfe lne did, absorb(ID#group_id year#group_id Gjcluster#group_id) vce(cluster Gjcluster#group_id)
est sto m1
global Controls6  " GZC roa lnAssests CPAEX LEV cr GDPgrowth 进出口占GDP populationrate"
global Controls7 " croa ClnAssests CCPAEX CLEV ccr cgdpgrowth C进出口占GDP Cpopulationrate samesountry  samesic"
reghdfe lne did   $Controls6 $Controls7   ,absorb(ID#group_id  year#group_id Gjcluster#group_id  ) vce(cluster Gjcluster# group_id )
est sto m2
outreg2 [m1 m2 ]using 主回归.doc, replace tstat bdec(3)tdec(2)addtext( Control VariablesS,YES,Control VariablesC,YES,Company#coheret FE,YES,Year#coheret  FE,YES,Country#coheret  FE,YES)
//Parallel Depopulation Test
reghdfe lne  Pre_3 Pre_2 Post_0  Post_1 Posts_2  $Controls6 $Controls7,absorb(ID#group_id  year#group_id  )  vce(cluster Gjcluster# group_id )
est sto m3
outreg2 [m3 ]using 平行趋势.doc, replace tstat bdec(3)tdec(2)addtext( Control VariablesS,YES,Control VariablesC,YES,Company#coheret FE,YES,Year#coheret  FE,YES,Country#coheret  FE,YES)
// Heterogeneity - carbon intensity
reghdfe lne did   $Controls6 $Controls7 if G碳密集==1  ,absorb(ID#group_id  year#group_id Gjcluster#group_id  ) vce(cluster Gjcluster# group_id )
est sto m4
reghdfe lne did   $Controls6 $Controls7 if G碳密集==0  ,absorb(ID#group_id  year#group_id Gjcluster#group_id  ) vce(cluster Gjcluster# group_id )
est sto m5
outreg2 [m4 m5 ]using 碳密集.doc, replace tstat bdec(3)tdec(2)addtext( Control VariablesS,YES,Control VariablesC,YES,Company#coheret FE,YES,Year#coheret  FE,YES,Country#coheret  FE,YES)
//Country Status
reghdfe lne did $Controls6 $Controls7 if GGJZT ==1& KHGJZT ==1,absorb(ID#group_id  year#group_id Gjcluster#group_id) vce(cluster Gjcluster# group_id)
 est sto m6
 reghdfe lne did  $Controls6 $Controls7 if GGJZT==1& KHGJZT ==0,absorb(ID#group_id  year#group_id Gjcluster#group_id) vce(cluster Gjcluster# group_id )
 est sto m7
 reghdfe lne did  $Controls6 $Controls7 if GGJZT==0& KHGJZT ==1,absorb(ID#group_id  year#group_id Gjcluster#group_id) vce(cluster Gjcluster# group_id )
 est sto m8
 reghdfe lne did  $Controls6 $Controls7 if GGJZT==0& KHGJZT ==0,absorb(ID#group_id  year#group_id Gjcluster#group_id) vce(cluster Gjcluster# group_id )
est sto m9
outreg2 [ m6 m7 m8 m9 ]using 国家状态.doc, replace tstat bdec(3)tdec(2)addtext( Control VariablesS,YES,Control VariablesC,YES,Company#coheret FE,YES,Year#coheret  FE,YES,Country#coheret  FE,YES)

//Robustness - Replacement of Y-values
reghdfe lnY2 did $Controls6 $Controls7 ,absorb(ID#group_id  year#group_id Gjcluster#group_id) vce(cluster Gjcluster# group_id )
est sto m11
reghdfe lnY3 did $Controls6 $Controls7 ,absorb(ID#group_id  year#group_id Gjcluster#group_id) vce(cluster Gjcluster# group_id )
est sto m12
outreg2 [ m11 m12 ]using 替换.doc, replace tstat bdec(3)tdec(2)addtext( Control VariablesS,YES,Control VariablesC,YES,Company#coheret FE,YES,Year#coheret  FE,YES,Country#coheret  FE,YES)
* Clearly after 2020
reghdfe lne did $Controls6 $Controls7 if year >= 2012 & year <=2020, ///
    absorb(ID#group_id year#group_id Gjcluster#group_id) ///
    vce(cluster Gjcluster#group_id)
est sto m13
outreg2 [ m13 ]using 2020.doc, replace tstat bdec(3)tdec(2)addtext( Control VariablesS,YES,Control VariablesC,YES,Company#coheret FE,YES,Year#coheret  FE,YES,Country#coheret  FE,YES)
*one period behind
egen panel_id = group(ID group_id)  
xtset panel_id year  
reghdfe lne L.did $Controls6 $Controls7 , ///
    absorb(ID#group_id year#group_id Gjcluster#group_id) ///
    vce(cluster Gjcluster#group_id)
est sto m14
outreg2 [ m14 ]using 滞后.doc, replace tstat bdec(3)tdec(2)addtext( Control VariablesS,YES,Control VariablesC,YES,Company#coheret FE,YES,Year#coheret  FE,YES,Country#coheret  FE,YES)
* Mechanism analysis
//esg
reghdfe esg did $Controls6 $Controls7 ,absorb(ID#group_id  year#group_id Gjcluster#group_id) vce(cluster Gjcluster# group_id )
est sto m6
//eis
reghdfe eis did $Controls6 $Controls7 ,absorb(ID#group_id  year#group_id Gjcluster#group_id) vce(cluster Gjcluster# group_id )
est sto m7
outreg2 [ m6 m7 ]using 机制.doc, replace tstat bdec(3)tdec(2)addtext( Control VariablesS,YES,Control VariablesC,YES,Company#coheret FE,YES,Year#coheret  FE,YES,Country#coheret  FE,YES)
* Robustness
// Stacked five-year period
use "C:\Users\21242\Desktop\数据重新处理\data0220.dta"
g never_treated=1 if policy_year==.
replace never_treated=0 if never_treated==.
egen max_treat= max(KZC), by(ID)
keep if policy_year >= 2012
levelsof policy_year if never_treated == 0 ,local(slist)
save stacking_raw, replace 
use  stacking_raw, clear
levelsof policy_year if never_treated == 0 ,local(slist)
foreach var of local slist  {
	display `var'
	use  stacking_raw, clear 
	gen group_id = `var'
	
	* keep the treated State_ID and never treated states 
	keep if (policy_year == `var' | never_treated == 1)
	
	* get the effective Yearfor the treated State_ID
	gen id_year_temp = policy_year if policy_year == `var' 
	egen id_year = max(id_year_temp)
	
	* keep 5 years pre-period and 5 years post-period
	keep if year <= (id_year+ 5) 
	keep if year >= (id_year- 5)

	save stacking2_raw_`var', replace
}
use  "stacking2_raw_2012.dta",clear
ap using "stacking2_raw_2013.dta"
ap using "stacking2_raw_2014.dta"
ap using "stacking2_raw_2016.dta"
ap using "stacking2_raw_2018.dta"
ap using "stacking2_raw_2019.dta"
ap using "stacking2_raw_2020.dta"
ap using "stacking2_raw_2021.dta"
ap using "stacking2_raw_2022.dta"
save stackall2.dta, replace
use stackall2.dta, clear
winsor2 lne lnY2 lnY3 , cut(1 99) replace
reghdfe lne did, absorb(ID#group_id year#group_id Gjcluster#group_id) vce(cluster Gjcluster#group_id)
reghdfe lne did   $Controls6 $Controls7   ,absorb(ID#group_id  year#group_id Gjcluster#group_id  ) vce(cluster Gjcluster# group_id )
est sto m10
outreg2 [ m10 ]using 堆叠.doc, replace tstat bdec(3)tdec(2)addtext( Control VariablesS,YES,Control VariablesC,YES,Company#coheret FE,YES,Year#coheret  FE,YES,Country#coheret  FE,YES)