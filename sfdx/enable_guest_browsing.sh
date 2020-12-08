#!/bin/sh

if [[ -z "$1" ]] || [[ -z "$2" ]]
then
	echo "You need to specify the name of the store and name of the buyer group."
	echo "Command should look like: ./enable-guest-browsing.sh <YourStoreName> <NameOfBuyerGroup>"
	exit 1
fi

communityNetworkName=$1
# If the name of the store starts with a digit, the CustomSite name will have a prepended X.
communitySiteName="$(echo $1 | sed -E 's/(^[0-9])/X\1/g')"
# The ExperienceBundle name is similar to the CustomSite name, but has a 1 appended.
communityExperienceBundleName="$communitySiteName"1
# To get the name of the config file, take community name and ensure first letter is lowercase.
firstletter=$(echo ${communityNetworkName:0:1} | tr '[:upper:]' '[:lower:]')
configname=$(echo "$firstletter${communityNetworkName:1}")

buyergroupName=$2

settingUpStore=false

if [[ ! -z "$3" ]] 
then    
	settingUpStore="$3"
fi
# If not setting up store, retrieve metadata
# Else work with metadata already retrieved through quickstart-setup-store
if [ "$settingUpStore" == false ]
then
	echo 
	echo
	echo "**** Standalone setup of Guest Browsing ****"
	echo
	echo
	pkgRtrvTmpFile=$(mktemp)
	sed -E "s/YourCommunitySiteNameHere/$communitySiteName/g;s/YourCommunityExperienceBundleNameHere/$communityExperienceBundleName/g;s/YourCommunityNetworkNameHere/$communityNetworkName/g" quickstart-config/package-retrieve-template.xml > $pkgRtrvTmpFile

	echo "Using this to retrieve your store info:"
	cat $pkgRtrvTmpFile

	echo "Retrieving the store metadata and extracting it from the zip file."
	sfdx force:mdapi:retrieve -r experience-bundle-package -k $pkgRtrvTmpFile
	unzip -d experience-bundle-package experience-bundle-package/unpackaged.zip
fi	

# Can only force:source:deploy from sfdx project folder
# Cannot use tmp folders
rm -rf putSourceGuestProfileHere
mkdir putSourceGuestProfileHere
# Cannot push source Guest Profile earlier as Store is not created yet
pathToGuestProfile="../examples/users/guest-user-profile-setup"
# Guest Profile has a space in the name. Do not be alarmed.
srcGuestProfile="$pathToGuestProfile/profiles/InsertStoreNameHere Profile.profile"
trgtGuestProfile="$pathToGuestProfile/profiles/$communityNetworkName Profile.profile"
mv "$srcGuestProfile" "$trgtGuestProfile"
sfdx force:mdapi:convert -r $pathToGuestProfile -d putSourceGuestProfileHere
sfdx force:source:deploy  -p putSourceGuestProfileHere
rm -r putSourceGuestProfileHere

# Sharing Rules
sharingRulesDir="quickstart-config/guestbrowsing/sharingRules"
productShareTemplate="$sharingRulesDir/Product2-template.sharingRules"
productCatalogShareTemplate="$sharingRulesDir/ProductCatalog-template.sharingRules"																								
actualProductShare="experience-bundle-package/unpackaged/sharingRules/Product2.sharingRules"
actualProductCatalogShare="experience-bundle-package/unpackaged/sharingRules/ProductCatalog.sharingRules"
sed -E "s/YourStoreName/$1/g" $productShareTemplate > $actualProductShare
sed -E "s/YourStoreName/$1/g" $productCatalogShareTemplate > $actualProductCatalogShare

# Make Site and Nav Menu Item Public
siteConfigMetaFile="experience-bundle-package/unpackaged/experiences/$communityExperienceBundleName/config/$configname.json"
tmpfile=$(mktemp)
sed -E "s/\"isAvailableToGuests\" : false/\"isAvailableToGuests\" : true/g" $siteConfigMetaFile > $tmpfile
mv -f $tmpfile $siteConfigMetaFile
navMenuItemMetaFile="experience-bundle-package/unpackaged/navigationMenus/Default_Navigation.navigationMenu"	
tmpfile=$(mktemp)
sed -E "s/<publiclyAvailable>false/<publiclyAvailable>true/g" $navMenuItemMetaFile > $tmpfile
mv -f $tmpfile $navMenuItemMetaFile

mv "$trgtGuestProfile" "$srcGuestProfile"

# Enable Guest Browsing for WebStore and create Guest Buyer Profile. 
# Assign to Buyer Group of choice.
sfdx force:data:record:update -s WebStore -v "OptionsGuestBrowsingEnabled='true'" -w "Name='$communityNetworkName'"
guestBuyerProfileId=`sfdx force:data:soql:query --query \ "SELECT GuestBuyerProfileId FROM WebStore WHERE Name = '$communityNetworkName'" -r csv |tail -n +2`
buyergroupID=`sfdx force:data:soql:query --query \ "SELECT Id FROM BuyerGroup WHERE Name = '${buyergroupName}'" -r csv |tail -n +2`
sfdx force:data:record:create -s BuyerGroupMember -v "BuyerId='$guestBuyerProfileId' BuyerGroupId='$buyergroupID'"

# Refactor? Use functions?
if [ "$settingUpStore" == false ] && [ -d "experience-bundle-package/unpackaged" ]
then
	echo "Creating the package to deploy, including the new flow."
	cd experience-bundle-package/unpackaged/
	cp -f ../../quickstart-config/package-deploy-template.xml package.xml
	zip -r -X ../"$communityExperienceBundleName"ToDeploy.zip *
	cd ../..

	# Uncomment the line below if you'd like to pause the script in order to save the zip file to deploy
	# read -p "Press any key to resume ..."

	echo "Deploy the new zip including the flow, ignoring warnings, then clean-up."
	sfdx force:mdapi:deploy -g -f experience-bundle-package/"$communityExperienceBundleName"ToDeploy.zip --wait -1 --verbose --singlepackage
	rm -fr experience-bundle-package

	echo "Removing the package xml files used for retrieving and deploying metadata at this step."
	rm $pkgRtrvTmpFile

	echo "Publishing the community."
	sfdx force:community:publish -n "$communityNetworkName"
	sleep 10s
fi


echo
echo
echo "Done! Guest Buyer Access is setup!"
echo
echo

