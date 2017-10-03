#!/bin/bash
#Author : - shivam rai
#debug mode off
#set -x
if [ $EUID != 0 ]
then
  echo "Please run this script as root! Better run with sudo."
  exit 1
fi

#initial vars
start=`date +%s`
bannerFlag=1
function banner {
    echo '---------------'
    echo  -e "\033[7m Scanner v0.0.1\033[0m"
    echo '---------------'
    echo ''
}

if [ $bannerFlag -eq 1 ]; then
banner;
bannerFlag=2
else
echo 'Unexpected error'
exit 1
fi
# Error module returns usage info with error code 1
function usage {
  echo ''
  #echo 'Error! illegal parameter(s)'
   cat << EOF
Usage 1: bash scanner.sh -d <path/to/Node/Project> -r <path/to/generate/report> -node
        (If you only want to include node_modules)    
Usage 2: bash scanner.sh -d <path/to/Node/Project> -r <path/to/generate/report> 
        (If you want to include Entire Directory including node_modules)        
EOF
   exit 1
}

node_path=$#

if [ $# -eq 4 ];then
    echo ''
elif [ $# -eq 5 ];then
    
  if [ "$5" != "-node" ]; then
  echo ''
  echo "missing -node flag, usage of ${5} is invalid"
  echo ''
  usage;
fi
else
    usage;
fi
# check dir flag
if [ "$1" != "-d" ]; then
  echo ''
  echo "missing -d flag, usage of ${1} is invalid"
  echo ''
  usage;
fi
#check output flag
if [ "$3" != "-r" ]; then
  echo ''
  echo "missing -r flag, usage of ${3} is invalid"
  echo ''
  usage;
fi

#append dir node_modules if flag is -node
if [ $# -eq 5 ]; then
   node_path="/node_modules"
elif [ $# -eq 4 ]; then
    node_path=""
fi

#path of node
pathToNode=$2
#path to generate report
pathToReport=$4
#if report folder is same as current folder
if [ "$pathToReport" == "." ]; then
pathToReport=$(pwd)
fi
#check if directory exists
if [ ! -d "$pathToNode" ]; then
  echo "provided node directory doesn't exist"
  exit 1
fi
#check if report directory exists if not create one
if [ ! -d "$pathToReport" ]; then
  echo "report directory doesn't exist"
  read -p "Do you wish to create this directory? (yes/no) " yn
  case $yn in
        y|yes|Y|Yes) mkdir $pathToReport
        ;;
        n|no|N|No ) exit 1
        ;;
        * ) echo "Invalid option"
            exit 1;;
    esac
fi
#check directory and remove  if extra '/' is present
if [[ $pathToNode =~ \/$ ]]; then
        pathToNode=$(echo $pathToNode|sed 's/.$//')
fi
if [[ $pathToReport =~ \/$ ]]; then
        pathToReport=$(echo $pathToReport|sed 's/.$//')
fi

#echo "$pathToNode""$node_path"
#find folder named as node_modules and if found counts
findTrue=$((find $pathToNode -maxdepth 1 -type d -name node_modules | wc -l) 2>&1)

exitC=$(echo $findTrue| sed "s/.*No such file or directory.*//")

if [ -z $exitC ]; then
echo 'Error ! Remove spaces from Node folder name'
exit 1
fi

if [ $findTrue -eq 0 ]; then
  echo "node_modules folder not found, make sure to specify correct path"
  exit 1
fi
#counts total number of folder in node_modules
totalScannedModules=$(ls $pathToNode/node_modules | wc -l)
#Eval regex
keyword='\beval(.*)'
#eval comment regex
falsePositive='\/\/\s.*eval(.*)'
echo ''
echo -e "\033[7mIn progress...please wait\033[0m"
echo ''

#recursive finding file having eval
directoryFile=$(grep -nr "$keyword" "$pathToNode""$node_path" --include=\*.js|cut -d: -f1,2) #! | rev|cut -d/ -f1| rev
#filtering file having eval in comments
falsePosDirectory=$(grep -nr "$falsePositive" "$pathToNode""$node_path" --include=\*.js|cut -d: -f1,2)
#stores the directory of the file which are not false positive
directoryFile=($(echo ${directoryFile[@]} ${falsePosDirectory[@]} | tr ' ' '\n'| sort |uniq -u))

#( IFS=$'\n'; echo "${directoryFile[*]}" )



foundListLength=${#directoryFile[@]}


#stores module names
declare -a modulename
for (( i=0; i<${foundListLength}; i++ ));
do
  modulename[i]=$(echo -e "${directoryFile[$i]} \n" | sed "s/.*\(\/node_modules\/\)/\1/"| grep -o '/node_modules/.*' | cut -d/ -f3)
done
#stores uniq module name
modulename=($(( IFS=$'\n'; echo "${modulename[*]}" ) | sort -u))



#getting script time while scanning
totaltime=$((($(date +%s)-$start)))
 
#generating report
DATE=$(date '+%Y-%m-%d %H:%M:%S')

reportName="report_$DATE"
touch "$reportName".html

echo "<html>" >> "$reportName".html
echo "<meta http-equiv=\"Content-Language\" content=\"en\">" >> "$reportName".html
echo "<body bgcolor=\"#E6E6FA\">" >> "$reportName".html
echo "<title>Scanner v0.0.1</title>" >> "$reportName".html
echo "<h1>Report generated by Scanner v0.0.1</h1>" >> "$reportName".html
echo -e "<h2>Total Scan time : $totaltime seconds</h2>" >> "$reportName".html
echo -e "<h2>Total Modules found in node_modules: $totalScannedModules</h2>" >> "$reportName".html
echo -e "<h2>Total eval found : $foundListLength</h2>" >> "$reportName".html

echo -e "<fieldset><legend>node_Modules using Eval</legend>" >> "$reportName".html
for module in "${modulename[@]}"; 
do 
echo -e "- $module <br>" >> "$reportName".html
done
echo -e "</fieldset>" >> "$reportName".html

echo "<h3>File Location</h3>" >> "$reportName".html
for link in "${directoryFile[@]}"; 
do 
lnk=$(echo $link | cut -d: -f1)
lineNumber=$(echo $link | cut -d: -f2)


#sleep 200
#outer if begin
if [ $# -eq 5 ];then
short=$(echo "$link" | sed "s/.*\(\/node_modules\/\)/\1/"| grep -o '/node_modules/.*' |cut -d/ -f3- | cut -d: -f1)
else
tmp=$(echo "$pathToNode" | wc -c)
short=$(echo "$link" | cut -b $tmp- | cut -d: -f1)
dir=$(echo $short | cut -d/ -f2)

#inner if begin
if [ "$dir" == "node_modules" ];
then 

short=$(echo "$link" | sed "s/.*\(\/node_modules\/\)/\1/"| grep -o '/node_modules/.*' |cut -d/ -f3- | cut -d: -f1)
stringnodename=" [node_modules]"
#inner if
fi
#outer if
fi



#echo -e "<a href="$lnk">"$short"</a>" >> report.html;

#check if node_modules 
#if [ -z $short ]; then
#echo 'eval not found'
#exit 1
#fi

echo -e "<div style=\"background: #E6E6FA; overflow:auto;width:auto;border:solid black;;border-width:.1em .1em .1em .1em;padding:.2em .6em;\"><pre style=\"margin: 0; line-height: 125%\"><a href="$lnk" STYLE=\"text-decoration: none\"><span style=\"color: #008800; font-weight: bold\"></span> <span style=\"background-color: #96D7FC\">open</a><h>" $short"<h><span style='font-weight: bold;color:blue;'>$stringnodename</span></h></h></span></a>\
<table align=\"right\">\
    <tr>\
    <th align=\"right\">Line Number: $lineNumber</th>\
  </tr>\
</table>\
</pre>\
</div>" >> "$reportName".html
done
echo "</body>" >> "$reportName".html
echo "</html>" >> "$reportName".html

if [ $bannerFlag -eq 2 ]; then
clear
banner;
fi

echo -e "\033[7mScan Complete with Report\033[0m\r"

echo "Moving Report to the destination $pathToReport"
sleep 2
mv "$reportName".html $pathToReport/

echo "Report File path : $pathToReport/"$reportName".html"
#checking os version to use open command
osV=$(uname)
if [ "$osV" == "Darwin" ]; then
open $pathToReport/"$reportName".html
fi


