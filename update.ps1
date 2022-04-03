#powershell

##
## requirements: git, OpenJDK17
##

#/usr/bin/java --version
#openjdk 17


$java = "/usr/bin/java"
$basedir = "/opt/data"
$selfdir = "$basedir/update-minecraft"
cd $basedir

# Buildtools
if(-not(test-path -path "$selfdir/spigot-buildtools")) { new-item -itemtype directory -path "$selfdir" -name "spigot-buildtools" }
cd "$selfdir/spigot-buildtools"
curl -o "BuildTools.jar" https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar

#get latest version
$ResponseVersions = Invoke-RestMethod -Method get -Uri  https://launchermeta.mojang.com/mc/game/version_manifest.json
$LatestVersion= $ResponseVersions.latest.release #1.18.2

#Folder create latest version
cd $selfdir
$previousVersion = get-childitem $basedir -Directory "minecraft-*" | sort-object -Property LastWriteTime -Descending | select -first 1 -expandproperty FullName #D:/Downloads/minecraft-1.18
if(-not(test-path -path "$basedir/minecraft-$LatestVersion")) { new-item -itemtype directory -path "$basedir" -name "minecraft-$LatestVersion" }
if($previousVersion -eq "minecraft-$LatestVersion") { write-output "Up to date.. $LatestVersion"; exit 0 } 

#execute buildtools
cd $selfdir/spigot-buildtools
& $java -jar "$selfdir/spigot-buildtools/BuildTools.jar" --rev $LatestVersion #might take a while..
Remove-Item -path "$selfdir/spigot-buildtools/*" -Exclude "*.jar" -Recurse -Force
# spigot-1.18.2.jar
# BuildTools.jar

# Copy preivous version, remove spigotOld.jar, update serverproperties, move spigotNew.jar
#
cd $basedir
copy-item  "minecraft-$previousVersion" "$basedir/minecraft-$LatestVersion/"
remove-item "$basedir/minecraft-$LatestVersion/spigot-*.jar"
$serverproperties = get-content -raw "$basedir/minecraft-$LatestVersion/server.properties"
$serverproperties -replace 'motd=The (.*?) Server', "motd=The $LastestVersion Server" | set-content "$basedir/minecraft-$LatestVersion/server.properties"
move-item  "$selfdir/spigot-buildtools/spigot-$LatestVersion.jar" "$basedir/minecraft-$LatestVersion/”

#fix backup path
#
#TARGET_DIR="/opt/data/minecraft-1.18.2" --> #TARGET_DIR="/opt/data/minecraft-LATESTVERSION"
$backup = get-content -raw "$basedir/linux-backup2gdrive/backup_job.conf" 
$backup -replace 'TARGET_DIR=".*"',"TARGET_DIR=`"$basedir/minecraft-$LatestVersion`"" | set-content "$basedir/linux-backup2gdrive/backup_job.conf"

#fix startup script
#blabalabout java and arugments  -jar /opt/data/minecraft-1.18.2/spigot-1.18.2.jar
$script = get-content -raw "$basedir/minecraft-$LatestVersion/start.sh" 
$script -replace "$basedir/minecraft-$previousVersion/spigot-$PreviousVersion.jar", "$basedir/minecraft-$LatestVersion/spigot-$LatestVersion.jar" | set-content "$basedir/minecraft-$LatestVersion/start.sh"
 
