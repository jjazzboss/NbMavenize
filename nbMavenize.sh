#!/bin/bash
# Jerome Lelasseux 2023 - Tested on Win10/cygwin
# =============================================================================================


function usage()
{
    echo "USAGE: nbMavenize [ant_module_dir] [maven_parent_project_dir]"
	echo "Imports an Ant-based module to a Maven-based project for a Netbeans platform application."	
	echo 
	echo "EXAMPLE: nbMavenize antNbApp/XmlParser mavenNbApp"
	echo
	echo "Imported module is stored in the 'modules' subdirectory of the maven parent project."	
	echo "The source and resources files are copied and the module pom.xml is created."
	echo "The pom.xml files of the parent and application projects are updated (if needed)."
	echo 
	echo "The script does not handle all possible cases. Search for 'MANUAL ACTION NEEDED' in the script"
	echo "output for examples of post-script required actions."
    exit
}



# The template pom.xml for a NB platform app module. Taken from the pom.xml created by the NB 17 wizard.
# $1 parent groupId
# $2 parent artifactId 
# $3 parent version
# $4 module artifactId
# $5 module name
function echoBaseModulePom()
{
	echo "
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<project xmlns=\"http://maven.apache.org/POM/4.0.0\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd\">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>$1</groupId>
        <artifactId>$2</artifactId>
        <version>$3</version>
        <relativePath>../../pom.xml</relativePath>
    </parent>
    <artifactId>$4</artifactId>
	<name>$5</name>
    <packaging>nbm</packaging>
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.netbeans.utilities</groupId>
                <artifactId>nbm-maven-plugin</artifactId>
                <configuration>
                    <publicPackages>                      
                    </publicPackages>
                </configuration>
                <extensions>true</extensions>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-jar-plugin</artifactId>
                <configuration>
                    <archive>
                        <manifestFile>\${project.build.outputDirectory}/META-INF/MANIFEST.MF</manifestFile>
                    </archive>
                </configuration>
            </plugin>
        </plugins>
    </build>
    <dependencies>      
    </dependencies>
    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
</project>
"
}



# ===================================================================================================
# MAIN
# ===================================================================================================


if [[ ! $# -eq 2 ]]
then
	usage
fi


srcDir="$1"
if [[ ! -e "$srcDir/manifest.mf" ]] || [[ ! -d "$srcDir/nbproject" ]] || [[ ! -d "$srcDir/src" ]]
then
	echo "Missing files in source Netbeans module directory $srcDir"	
	exit
fi
moduleName=$(basename $srcDir)
moduleCodeNameDot=$(grep "^[[:blank:]]*OpenIDE-Module *:" $srcDir/manifest.mf | sed -e 's/^ *OpenIDE-Module *: *//' | tr -d '\r') # get rid of annoying trailing \n
moduleCodeNameDash=$(echo $moduleCodeNameDot | tr . -)		
moduleCodeNameSlash=$(echo $moduleCodeNameDot | tr . /)
moduleNameLo=${moduleName,,}			# lower case



destDir="$2"
targetFile="$destDir/pom.xml"
if [[ ! -e "$targetFile" ]]
then
	echo "Missing file $targetFile"
	exit
fi
destModuleDir="$destDir/modules/$moduleName"
destModuleDirAbs=$(realpath $destModuleDir)
parentGroupId=$(grep -m 1 "^[[:blank:]]*<groupId>" $targetFile  | sed -E 's/ *<\/?groupId> *//g' | tr -d '\r')
parentArtifactId=$(grep -m 1 "^[[:blank:]]*<artifactId>" $targetFile  | sed -E 's/ *<\/?artifactId> *//g' | tr -d '\r')
parentVersion=$(grep -m 1 "^[[:blank:]]*<version>" $targetFile  | sed -E 's/ *<\/?version> *//g' | tr -d '\r')



echo -e "\n\n=========================================================================================="
echo "=========================================================================================="
echo "IMPORTING moduleName=$moduleName  moduleCodeNameDot=$moduleCodeNameDot  destModuleDir=$destModuleDir"
echo "=========================================================================================="
echo "=========================================================================================="



if [[ -d "$destModuleDir" ]]
then
	echo "$destModuleDir already exists"
	exit
fi



targetFile="$destModuleDir/pom.xml"
echo -e "\nInitializing $destModuleDir and $targetFile ==============="
set -o xtrace
mkdir -p $destModuleDir/src/main/java
mkdir -p $destModuleDir/src/main/nbm
mkdir -p $destModuleDir/src/main/resources
set +o xtrace
echo "Creating $targetFile..."
echoBaseModulePom $parentGroupId $parentArtifactId $parentVersion $moduleCodeNameDash $moduleName > $targetFile



srcFile="$srcDir/manifest.mf"
targetFile="$destModuleDir/src/main/nbm/manifest.mf"
echo -e "\nCopying and adapting $targetFile =============="
set -o xtrace
cat $srcFile | grep -Ev  "^[[:blank:]]*(OpenIDE-Module-Specification-Version|OpenIDE-Module)[[:blank:]]*:" > $targetFile
cat $targetFile
set +o xtrace



echo -e "\nCopying source files (.java .form .pdf .txt) ===================="
set -o xtrace
cd $srcDir/src
find . -type f \( -iname '*.java' -o -iname '*.form' -o -iname '*.pdf' -o -iname '*.txt' \) | xargs cp -v --parents -t $destModuleDirAbs/src/main/java
cd -
set +o xtrace


echo -e "\nCopying resources files ====================="
set -o xtrace
cd $srcDir/src
find . -type f -not \( -iname '*.java' -o -iname '*.form' -o -iname '*.pdf' -o -iname '*.txt' \) | xargs cp -v --parents -t $destModuleDirAbs/src/main/resources
cd -
set +o xtrace


targetFile="$destDir/pom.xml"
echo -e "\nAdding module $moduleName to parent $targetFile ====================="
if ! grep -qi ">modules/$moduleName<" $targetFile ; then
	set -o xtrace
	sed -i "s/<\/modules>/<module>modules\/$moduleName<\/module><\/modules>/" $targetFile
	set +o xtrace	
else
	echo " > pom.xml was already updated"
fi


targetFile="$destDir/application/pom.xml"
echo -e "\nAdding dependency on $moduleCodeNameDash in application $targetFile ====================="
if ! grep -qi "artifactId>$moduleCodeNameDash<" $targetFile; then
	set -o xtrace
	sed -i "s/<\/dependencies>/ <dependency> <groupId>\$\{project\.groupId\}<\/groupId> <artifactId>$moduleCodeNameDash<\/artifactId> <version>\$\{project\.version\}<\/version> <\/dependency> <\/dependencies>/" $targetFile
	set +o xtrace	
else
	echo " > pom.xml was already updated"
fi

srcProjectXml="$srcDir/nbproject/project.xml"
targetFile="$destModuleDir/pom.xml"


echo -e "\nAdding public packages in module $targetFile ====================="
set +o xtrace
# Get source public packages
pkgs=$(grep "<package>" $srcProjectXml | sed -E 's/[[:blank:]]*<\/?package>[[:blank:]]*//g')
for pkg in $pkgs; do
	pkg=$(echo $pkg | tr -d '\r')			# get rid of annoying ending CR
	if ! grep -qi "publicPackage>$pkg<" $targetFile; then
		echo " > adding public package $pkg"
		sed -i "s/<\/publicPackages>/ <publicPackage>$pkg<\/publicPackage>\n<\/publicPackages>/" $targetFile
	fi	
done


targetFile="$destModuleDir/pom.xml"
echo -e "\nAdding non-Netbeans platform dependencies in module $targetFile ====================="
# Note that project.xml contains also a code-name-base for the module itself, so we need to remove it too
pkgs=$(grep '<code-name-base>' $srcProjectXml | grep -v -E "org.(netbeans|openide)"  | grep -v ">$moduleCodeNameDot<" \
        | sed -E 's/[[:blank:]]*<\/?code-name-base>[[:blank:]]*//g')
for pkg in $pkgs; do
	pkg=$(echo $pkg | tr . - | tr -d '\r')          # get rid of annoying ending CR
	if ! grep -qi "<artifactId>$pkg<" $targetFile; then
		echo " > adding dependency to $pkg"
		sed -i "s/<\/dependencies>/ <dependency> <groupId>\$\{project\.groupId\}<\/groupId> <artifactId>$pkg<\/artifactId> <version>\$\{project\.version\}<\/version>  <\/dependency> <\/dependencies>/" $targetFile
	fi	
done


targetFile="$destModuleDir/pom.xml"
echo -e "\nAdding Netbeans platform dependencies in module $targetFile (excluding unit test dependencies) ====================="
pkgs=$(grep -E "<code-name-base>org.(netbeans|openide)" $srcProjectXml | grep -v "junit" | sed -E 's/[[:blank:]]*<\/?code-name-base>[[:blank:]]*//g')
for pkg in $pkgs; do
	pkg=$(echo $pkg | tr . - | tr -d '\r')          # get rid of annoying ending CR
	if ! grep -qi "<artifactId>$pkg<" $targetFile; then
		echo " > adding dependency to $pkg"
		sed -i "s/<\/dependencies>/ <dependency> <groupId>org.netbeans.api<\/groupId> <artifactId>$pkg<\/artifactId> <version>\$\{netbeans\.version\}<\/version>  <\/dependency> <\/dependencies>/" $targetFile
	fi	
done


echo -e "\nChecking for post-script manual actions required ====================="
if grep -q '^[[:blank:]]*<implementation-version/>' $srcProjectXml;
then
	echo "## MANUAL ACTION NEEDED: There are one or more implementation-version dependencies in $srcProjectXml. You will need to manually update $targetFile to configure the nbm-maven-plugin accordingly: check the online doc for goal=manifest, parameter=moduleDependencies, type=impl"
fi
doReleaseDirCheck=true
grep -q '^[[:blank:]]*<binary-origin' $srcProjectXml
if [[ $? -eq 0 ]]
then
	echo "## MANUAL ACTION NEEDED: There are one or more external libraries specified in $srcProjectXml. You will need to manually add the corresponding dependencies in $targetFile"
	doReleaseDirCheck=false
fi
if $doReleaseDirCheck && [[ -d $srcDir/release ]] 
then
	echo "## MANUAL ACTION NEEDED: There is a release subdirectory in $srcProjectXml. You will need to manually copy the release files and update $targetFile to configure the nbm-maven-plugin accordingly: check the online doc for goal=nbm, parameter=nbmResources"
fi

