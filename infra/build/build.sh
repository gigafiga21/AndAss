#!/bin/sh

# Aliases
# Place aliaces for bundletool, d8, javac, aapt2, etc. commands if need
if `test -f "Aliases.sh"`; then
    printf "\n\tlog: loading command aliaces...\n"
    source Aliases.sh;
fi

# Aliases for binary files
# Delete this if you dont need or edit paths
alias d8="d8.bat"
alias bundletool="java -jar C:/Android/build-tools/29.0.3/bundletool.jar"

# {Path} ANDROID - path to android.jar file
# {Path} ROOT    - root folder of the project
# {Path} OBJ     - folder with tmp building files
# {Path} BUILD   - folder with resulting file
# {Path} SOURCE  - java code directory
ANDROID="C:/Android/platforms/android-23/android.jar";
ROOT="./"
OBJ="./object"
BUILD="./build"
SOURCE="source"

# Creating suitable folders in $OBJ folder
`[ ! -d $OBJ ] && mkdir $OBJ`;
`[ ! -d $BUILD ] && mkdir $BUILD`;
`[ ! -d $OBJ/R ] && mkdir $OBJ/R`;
`[ ! -d $OBJ/java ] && mkdir $OBJ/java`;

# Compiling resources into zip archieve
printf "\n\tlog: compiling resources...\n";
`aapt2 compile --dir ./$SOURCE/res -o $OBJ/compiled.zip`;

# Generating *.pb file contains resource list
# Generating R.java class
printf "\tlog: linking resources...\n";
`aapt2 link --proto-format -o $OBJ/linked.zip \
    -I $ANDROID \
    --manifest ./AndroidManifest.xml \
    -R $OBJ/compiled.zip \
    --auto-add-overlay \
    --java $OBJ/R`;

# Compiling java code into bytecode
# Includes R and MainActivity classes
printf "\tlog: compiling source code...\n";
`javac $(find ./$SOURCE/java -name "*.java") -bootclasspath $ANDROID $(find $OBJ/R -name "R.java") -d $OBJ/java`;

# Generating classes.dex file
printf "\tlog: dexing bytecode...\n";
`d8 $(find $OBJ/java -name "*.class") --classpath $ANDROID --output $OBJ`

# Creating *.aab bundle
printf "\tlog: bundling...\n";
`[ -d $OBJ/app ] && rm -rf $OBJ/app/*`
`[ -f $OBJ/app.zip ] && rm $OBJ/app.zip`
`[ -f $OBJ/app.aab ] && rm $OBJ/app.aab`
`7z x $OBJ/linked.zip -o$OBJ/app`;
`mkdir $OBJ/app/manifest`;
`mv $OBJ/app/AndroidManifest.xml $OBJ/app/manifest/`
`mkdir $OBJ/app/dex && cp $OBJ/classes.dex $OBJ/app/dex/`;
`7z a -mx0 $OBJ/app.zip $OBJ/app/*`;
`bundletool build-bundle --modules=$OBJ/app.zip --output=$OBJ/app.aab`;

# Generating target *.apks archieve with target *.apk files
printf "\tlog: generating apks...\n";
`[ -f $BUILD/app.apks ] && rm $BUILD/app.apks`
`bundletool build-apks --bundle=$OBJ/app.aab --output=$BUILD/app.apks`;
