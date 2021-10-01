pwd
cd "C:\Users\t_ana\OneDrive\Documents\Ana Maria\data science"

**[download from: https://www.europeansocialsurvey.org/download.html?file=ESS8e02_2&y=2016]
use ESS8

count
describe



keep essround cntry idno nwspol wrclmch clmchng
drop if cntry!="NL" 
count

*Look for missing values 
search mdesc /* install the program*/
mdesc
ssc install asdoc
asdoc mdesc, title(Missing values) save(missing_values.doc), replace



**** recode essround and gen and label new variables survey
recode essround (8=8 "ESS round 8") (9=9 "ESS round 9") (913=913 "Eurobarameter 2019"), gen(survey) 
label variable survey "Source of survey (8: ESS round 8) (9: ESS round 9) (913: Eurobarameter 2019)"
drop essround
order survey, first /* to bring survey to first place within list of variables*/



codebook nwspol
tab nwspol, m
codebook cntry

**************variable nwspol*****************

* Clean data
replace nwspol=. if nwspol==.c
* Nwspol transformed from minutes to hours
gen nwspol_hour=nwspol/60 
label variable nwspol_hour "News about politics and current affairs reading watching listening in hours"
* Nwspol_hour was grouped with cuts of 1 hour each to avoid visualizing fraction hours. New var generated grouped_nwspol_hour
egen grouped_nwspol_hour= cut(nwspol_hour), at(0(1)21)
label variable grouped_nwspol_hour "nwspol_hour grouped with cuts of 1 hour"



* looking for outliers

graph box grouped_nwspol_hour, mark(1, mlabel(grouped_nwspol_hour))

*** I will create a new variable that does not contain the outliers that exceeed 6, as indicated in the graph box as outliers. 

sum grouped_nwspol_hour
gen grouped_nwspol_hour_5=grouped_nwspol_hour
replace grouped_nwspol_hour_5=. if grouped_nwspol_hour_5>=6
label variable grouped_nwspol_hour_5 "grouped_nwspol_hour w/o outliers"

*** I will code grouped_nwspol_hour_5 to facilitate visualization in graphs and tabs
tab grouped_nwspol_hour_5
recode grouped_nwspol_hour_5 (0=0 "< 1 hour") (1=1 "1-2 hours") (2=2 "2-3 hours") (3/5=3 ">3 hours"),gen(news_hours_cat)
label variable news_hours_cat "Recode of grouped_nwspol_hour_5 (0 = < 1 hour) (1= 1-2 hours) (2= 2-3 hours) (3= >3 hours)"
tab news_hours_cat



**************variable wrclmch*****************

* clean data
tab wrclmch, m
codebook wrclmch
replace wrclmch=. if wrclmch==.a
replace wrclmch=. if wrclmch==.c



*** Preparation of data for further analysis: to see later whether there is a trend between time watching news and worriness on climate change, I will have to create new variables in order to generate a table summarizing the data on level of worriness and making comparisons across the hours spent getting informed about news

codebook wrclmch

gen very_worried=. if wrclmch!=4
replace very_worried=1 if wrclmch==4
label variable very_worried "Very worried about climate change"

gen extreme_worried=. if wrclmch!=5
replace extreme_worried=1 if wrclmch==5
label variable extreme_worried "Extremely worried about climate change"

gen some_worried=. if wrclmch!=3
replace some_worried=1 if wrclmch==3
label variable some_worried "Somewhat worried about climate change"

gen not_very_worried=. if wrclmch!=2
replace not_very_worried=1 if wrclmch==2
label variable not_very_worried "Not very worried about climate change"

gen not_at_all_worried=. if wrclmch!=1
replace not_at_all_worried=1 if wrclmch==1
label variable not_at_all_worried "Not at all worried about climate change"



**************variable clmchng*****************


*clean data 
tab clmchng, m
codebook clmchng
replace clmchng=. if clmchng==.c


*** Preparation of data for further analysis: to see later whether there is a trend between time watching news and awareness on climate change, I will have to create new variables in order to generate a table summarizing the data on level of awareness and making comparisons across the hours spent getting informed about news

codebook clmchng

gen definitively=. if clmchng!=1
replace definitively=1 if clmchng==1
label variable definitively "Climate is definitively changing"

gen probably=. if clmchng!=2
replace probably=1 if clmchng==2
label variable probably "Climate is probably changing"

gen probably_not=. if clmchng!=3
replace probably_not=1 if clmchng==3
label variable probably_not "Climate is probably not changing"

gen definitively_not=. if clmchng!=4
replace definitively_not=1 if clmchng==4
label variable definitively_not "Climate is definitively not changing"


**** Preparation of data on variables wrclmch, clmchng and some other new variable for conducting later confidence intervals and hypothesis testing 

*** create a dummy variable****  extremely worried gets a 1 and all the rest categories takes 0
codebook wrclmch
gen worriness=0 if wrclmch!=.
replace worriness=1 if wrclmch==5
label variable worriness "Extreme worriness about climate change (1=Yes; 0=Otherwise)"

*** create a second dummy variable**** climate change is definitively changing gets a 1 and the rest of categories a 0
codebook clmchng
gen awareness=0 if clmchng!=.
replace awareness=1 if clmchng==1
label variable awareness "Climate change is definitively changing (1=Yes; 0=Otherwise)"

***create a new variable that takes the values of variable worriness in order to compare it later with data from Eurobarameter on the seriousness of climate change. 

* from Eurobarameter database I got to know that people that considered that climate change is an extremely serious problem in the Netherlands is 17%. I am going to normalize both distributions and test them appropriately later

gen opinion_about_CCH = worriness
label variable opinion_about_CCH "Climate change is definitively changing or is a serious problem (1=Yes; 0=Otherwise)"

**** Before preparing the datasets that are going to be merged, I will save all the work until now and then clear all
save ESS8_before_merging, replace
clear


***********PREPARATION OF DATABASE EUROBARAMETER FOR MERGING******


*****MERGE DATABASE 1 (Eurobarameter_2019_913) *********

* Preparing Eurobarameter_2019_913 for merging: clean, rename, gen, replace and label were needed 
pwd
cd "C:\Users\t_ana\OneDrive\Documents\Ana Maria\data science"
use Eurobarameter_2019_913
keep survey isocntry qb2
drop if isocntry!="NL"
rename isocntry cntry


replace qb2=. if qb2==11
codebook qb2
gen opinion_about_CCH=0 if qb2!=.
replace opinion_about_CCH=1 if qb2==10
label variable opinion_about_CCH "Climate change is definitively changing or is a serious problem (1=Yes; 0=Otherwise)"

* Once the Dataset Eurobarameter is ready, I will save it and clear all
save Eurobarameter_2019_913_append, replace
clear

* The merging operation*
pwd
cd "C:\Users\t_ana\OneDrive\Documents\Ana Maria\data science"
use ESS8_before_merging

 merge m:m survey using "Eurobarameter_2019_913_append"
 save ESS8_with_merge_1, replace
clear



***********PREPARATION OF DATABASE ESS ROUND 9 FOR MERGING******

*** Preparing ESS Round 9 for merging: clean, recode, new variables

pwd
cd "C:\Users\t_ana\OneDrive\Documents\Ana Maria\data science"

**[download from: https://www.europeansocialsurvey.org/download.html?file=ESS9e03_1&y=2018]

use ESS9e02
keep essround idno cntry nwspol
drop if cntry!="NL"
rename essround survey
label variable survey "Source of Survey"

gen nwspol_hour=nwspol/60
label variable nwspol_hour "News about politics and current affairs reading watching listening in hours"
egen grouped_nwspol_hour= cut(nwspol_hour), at(0(1)24)
label variable grouped_nwspol_hour "nwspol_hour grouped with cuts of 1 hour"
tab grouped_nwspol_hour


* looking for outliers

graph box grouped_nwspol_hour, mark(1, mlabel(grouped_nwspol_hour))

* I will create a new variable that does not contain the outliers that exceeed 3, as indicated in the graph box as outliers. 

sum grouped_nwspol_hour
gen grouped_nwspol_hour_3=grouped_nwspol_hour
label variable grouped_nwspol_hour_3 "grouped_nwspol_hour w/o outliers"
replace grouped_nwspol_hour_3=. if grouped_nwspol_hour_3>=3

* I will code the variable grouped_nwspol_hour_3
tab grouped_nwspol_hour_3
recode grouped_nwspol_hour_3 (0=0 "< 1 hour") (1=1 "1-2 hours") (2=2 "2-3 hours"), gen(news_hours_cat)
label variable news_hours_cat "Recode of grouped_nwspol_hour_3 (0 = < 1 hour) (1= 1-2 hours) (2= 2-3 hours)"
tab news_hours_cat

save ESS2019_append, replace
clear

**** The actual merge operation of ESS round 9
pwd
cd "C:\Users\t_ana\OneDrive\Documents\Ana Maria\data science"
use ESS8_with_merge_1
drop _merge

merge m:m survey using "ESS2019_append"
drop _merge




***** DESCRIPTIVE STATISTICS****
*** news_hours_cat******

ssc install asdoc
asdoc tabstat grouped_nwspol_hour if survey!=913, by(survey) statistics(N sd mean median range min max var skewness p10 p25 p50 p75) title(Hours seeing news by survey) save(hours_news_survey.doc), replace

hist grouped_nwspol_hour if survey!=913, by(survey) fcolor(blue*0.7) lcolor(blue*0.7) title("Hours spent on news") xlabel(0(1)20) xtitle("hours") ytitle("density") normal


* looking for outliers
graph box grouped_nwspol_hour if survey!=913, by(survey) mark(1, mlabel(grouped_nwspol_hour)) title("Outliers") ytitle(frequencies)

asdoc tabstat news_hours_cat, by(survey) statistics(N sd mean median range min max var skewness p10 p25 p50 p75) title(Hours seeing news by survey w/o outliers) save(hours_news_survey_no_outliers.doc), replace


**********wrclmch************

*** descriptive statistics about wrclmch

sum wrclmch, detail

asdoc tabstat wrclmch, statistics(N sd mean median range min max var skewness p10 p25 p50 p75) title(How much worried about climate change?) save(descriptive_worriness.doc), replace

asdoc tabstat extreme_worried very_worried some_worried not_very_worried not_at_all_worried, by(news_hours_cat) statistics(count) title(Table worriness and hours spent on news) save(worriness_hours_NL2.doc), replace

hist wrclmch, normal discrete percent barwidth(0.4) color(blue) xlabel(1 "Not at all" 2 "Not Very" 3 "Somewhat" 4 "Very" 5"Extremely") title("Worries about climate change")
(start=1, width=1)


****Relationship between time and worriness
asdoc tab  wrclmch news_hours_cat, row title(Table worriness and hours spent on news) save(worriness_hours_NL.doc), replace


***Graph 1***** 
graph bar (percent) extreme_worried very_worried some_worried not_very_worried not_at_all_worried, over(news_hours_cat) legend(lab(1 "extreme worried") lab(2 "very worried") lab(3 "somewhat worried") lab(4 "not very worried") lab(5 "not at all worried")) ysize(20) xsize(15) subtitle(Worriness climate change by time seeing news) ytitle(Percentage) blabel(bar, position(center) format(%4.1f)) stack

***Graph 2
graph bar (percent) extreme_worried very_worried some_worried not_very_worried not_at_all_worried, over(news_hours_cat) by(wrclmch) ytitle(Percentage) blabel(bar, format(%4.1f)) xsize(8) ylabel(0(10)60)



**********clmchng************

*** descriptive statistics about wrclmch
sum clmchng, detail
asdoc tabstat clmchng, statistics(N sd mean median range min max var skewness p10 p25 p50 p75) title(How much aware about climate change?) save(descriptive_awareness.doc), replace

asdoc tabstat definitively probably probably_not definitively_not, by(news_hours_cat) statistics(count) title(Table awareness and hours spent on news) save(awareness_hours_NL2.doc), replace

hist clmchng, normal discrete percent barwidth(0.4) color(blue) xlabel(1 "Definitively" 2 "Probably" 3 "Probably not" 4 "Definitively not") title("Awareness about climate change")
(start=1, width=1)

****Relationship between time and worriness

asdoc tab clmchng news_hours_cat, row title(Table awareness and hours spent on news) save(awareness_hours_NL.doc), replace


***Graph 1****** 
graph bar (percent) definitively probably probably_not definitively_not, over(news_hours_cat) xsize(7) legend(lab(1 "definitively changing") lab(2 "probably changing") lab(3 "probably not changing") lab(4 "definitively not changing")) subtitle(Awareness climate change by time seeing news) ytitle(Percentage) blabel(bar, size(vsmall) position(base) format(%4.1f)) stack


***Graph 2
graph bar (percent) definitively probably probably_not definitively_not, over(news_hours_cat) by(clmchng) ytitle(Percentage) blabel(bar, format(%4.1f)) xsize(8)


**** Variation between awareness and worriness in their interaction with time on news *****

*** now I am going to compare the two relationships already made before, to see the differences closely
*** Graph on different variables
codebook wrclmch
slideplot hbar wrclmch, neg(1 2) pos(4 5) by(news_hours_cat) ylabel(-30(10)100)  subtitle(Level of worriness and Time watching news) percent saving (graph1)

codebook clmchng
slideplot hbar clmchng, neg(3 4) pos(1 2) by(news_hours_cat) ylabel(-30(10)100)subtitle(Awareness of climate change and Time watching news) percent saving (graph2)

graph combine "graph1" "graph2", row(3)



**** Confidence Interval *****

**** FIRST CONFIDENCE INTERVAL****

ci prop worriness

*we are 95% confident that the true proportion of people who worries extremly about climate change lies between 4.16% and 6.36% in the Dutch population. And average proportion is 5.18%


***** SECOND CONFIDENCE INTERVAL*****

ci prop awareness 


*we are 95% confident that the true proportion of people who regard that climate change is definitively changing lies between 65.94% and 70.46% in the Dutch population. And average proportion is 68.24%


****** THIRD CONFIDENCE INTERVAL*****

ci mean news_hours_cat


***we are 95% confident that the true mean of hours that Dutch people spent seeing news lies between 0.81 hours and 0.90 hours per day. And average of 0.85



******* HYPOTHESIS TESTING**************
***** HYPOTHESIS 1 *******
*worriness and exposition to the media


sort worriness
by worriness: sum news_hours_cat
ttest news_hours_cat, by(worriness)

** Conclusion: we cannot reject the Ho

***** HYPOTHESIS 2 *******
*awareness and exposition to the media


sort awareness
by awareness: sum news_hours_cat
ttest news_hours_cat, by(awareness)



*** Conclusion: we can reject the Ho


***** HYPOTHESIS 3 (WITH MERGE DATASET EUROBARAMETER) *******

sum opinion_about_CCH if survey==8
sum opinion_about_CCH if survey==913
 prtest opinion_about_CCH if survey!=9, by(survey)
 


 * Conclusion: we can reject the H0
 


**** HYPOTHESIS 4 (WITH MERGE DATASET ESSROUND 9)******


sum news_hours_cat if survey==8
sum news_hours_cat if survey==9
 ttest news_hours_cat, by(survey)
 
* Conclusion: We can reject the Ho 
 
 save ESS8_with_merge_1_and_2, replace
clear
 
 

