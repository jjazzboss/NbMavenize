#!/bin/bash
# Jerome Lelasseux 2023 - Tested on Win10/cygwin
# =============================================================================================


function usage()
{
    echo "USAGE: nbMavenizeAll [ant_project_dir] [maven_parent_project_dir]"
	echo "Run nbMavenize on all modules found in ant_project_dir."
	echo 
	echo "EXAMPLE: nbMavenizeAll antNbApp mavenNbApp"
    exit
}

if [[ ! $# -eq 2 ]]
then
	usage
fi

srcDir="$1"
if [[ ! -d "$srcDir/nbproject" ]] || [[ -d "$srcDir/src" ]]
then
	echo "Invalid Ant-based Netbeans platform application directory $srcDir"	
	exit
fi

destDir="$2"


for dir in $srcDir/*/; 
do 
	dir=${dir%/}
	echo "$dir"
	if [[ -d $dir/nbproject ]]
	then
		./nbMavenize.sh $dir $destDir
	fi
done


