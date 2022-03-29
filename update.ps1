#powershell

##
## requirements: git, OpenJDK17
##

#/usr/bin/java --version
#openjdk 17

$java = "/usr/bin/java"
$basedir = "/opt/data"
cd $basedir
git config --global --unset core.autocrlf

#build
if(-not(test-path -path "$basedir\spigot-buildtools")) { new-item -itemtype directory -path "$basedir" -name "spigot-buildtools" }
cd "$basedir\spigot-buildtools"
curl -o "$basedir\spigot-buildtools\BuildTools.jar" https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar

#get latest version
$ResponseVersions = Invoke-RestMethod -Method get -Uri  https://launchermeta.mojang.com/mc/game/version_manifest.json
$LatestVersion= $ResponseVersions.latest.release
# $LatestVersionData= $ResponseVersions.versions.where({$_.id -eq "$LatestVersion" -and $_.type -eq "release" }) #not needed
# $ResponseLatest = Invoke-RestMethod -Method get -Uri  $LatestVersionData.url #not needed
# $ServerJarURL=$ResponseLatest.downloads.server.url #not needed

#download latest version
$previousVersion = get-childitem $basedir -Directory "minecraft-*" | sort -Property LastWriteTime -Descending | select -first 1 -expandproperty FullName #D:\Downloads\minecraft-1.18
if(-not(test-path -path "$basedir\minecraft-$LatestVersion")) { new-item -itemtype directory -path "$basedir" -name "minecraft-$LatestVersion" }
# curl -o "$basedir/$LatestVersion/server-$LatestVersion.jar" $ServerJarURL #not needed

#execute buildtools
& $java -jar "$basedir\spigot-buildtools\BuildTools.jar" --rev $LatestVersion
Remove-Item -path "$basedir\spigot-buildtools\*" -Exclude "*.jar" -Recurse -Force
# spigot-1.18.2.jar
# BuildTools.jar

copy-item  "$previousVersion" "$basedir\minecraft-$LatestVersion\"
remove-item "$basedir\minecraft-$LatestVersion\spigot-*.jar"
$serverproperties = get-content -raw "$basedir\minecraft-$LatestVersion\server.properties"
$serverproperties -replace 'motd=The (.*?) Server', "motd=The $LastestVersion Server" | set-content "$basedir\minecraft-$LatestVersion\server.properties"
move-item  "$basedir\spigot-buildtools\spigot-$LatestVersion.jar" "$basedir\minecraft-$LatestVersion\"
