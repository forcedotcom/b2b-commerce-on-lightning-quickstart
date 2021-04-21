# SFDX

This is a quick and easy deployment of a Lightning B2B testing environment using SFDX and shell scripts.

This repository provides configuration files and scripts that a Salesforce developer can use to setup a SFDX project in order to deploy the testing environment. The SFDX will include the metadata from the **examples** directory, converted to the SFDX format, and will have additional scripts for deployment steps supported only in the SFDX environment.

## Getting Started

### SFDX Setup
1. Before continuing with the steps below, see [Salesforce DX Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm) to setup SFDX.

2. Additionally, please install the 1Commerce SFDX Plugin: https://github.com/forcedotcom/sfdx-1commerce-plugin


### Quick Start

1. Clone the whole b2b-commerce-for-lightning repository:
```
git clone <Repository URL>
```
If you cannot clone from that location, download the .zip file and unzip it locally.

2. From the sfdx directory, run the script
```
./convert-examples-to-sfdx.sh
```
that will convert the examples from the metadata API format to the SFDX format and add them to the "path" you have specified in the sfdx-project.json file.

3. Create a scratch org using SFDX:
If you don't have a dev hub already authorized, do that now by running
```
sfdx force:auth:web:login -d
```
This will open a new browser window where you have to enter the credentials of your Dev Hub. The -d option will set that Dev Hub as your default one. Once you're logged in, the Dev Hub is authorized and you can close the browser. The Dev Hub will manage your future scratch orgs.

Run the command that creates the scratch org and specify the username for the administrator:
```
sfdx force:org:create -f config/project-scratch-def.json username=<YourScratchOrgUsernameInEmailFormat> -s -d <DurationInDays>
```
This command may take a while to run (minutes, but not more than 5-10 minutes) and you won't see output while it's running. A password for your user is auto-generated but it's hidden.

To open the new org:
```
sfdx force:org:open
```
Note: if that fails, you might need to first set that new scratch org as your default org with
```
sfdx force:config:set defaultusername=<YourScratchOrgUsernameInEmailFormat>
```

Notice that the existing settings in the ```project-scratch-def.json``` file will enable all the necessary licenses and org perms and prefs required for Lightning B2B. If the scratch org creation is successful you should not need to modify any org perms or prefs. This is only available for the scratch orgs though, and will not work for sandboxes or other environments. For those orgs, follow the documentation about the licenses and org preferences that need to be enabled for B2B on Lightning.

4. Make sure that your current directory is sfdx and create and setup a new store in your new scratch org by running the following script:
```
./quickstart-create-store.sh
```

You are done!

### Manual Steps

## Push Samples
This is taken care of in step 4 of the Quick Start instructions above. However, if you wish to push updated samples to the new org:
```
sfdx force:source:push -f
```
## Setup Store
This is also triggered by step 4 of the Quick Start instructions above. You would only need to run this step if you wanted to setup a store again. If you have a store already created (from the previous step or because you created it manually), first, make sure to adjust configuration settings such as Username and/or Email in the definition file for your Buyer User at config/buyer-user-def.json. Then run the following script to setup your store:
```
./quickstart-setup-store.sh <YourStoreName>
```
This script will:
 - register the Apex classes needed for checkout integrations and map them to your store
 - associate the clone of the checkout flow to the checkout component in your store
 - add the Customer Community Plus Profile clone to the list of members for the store
 - import Products and necessary related store data in order to get you started
 - create a Buyer User and attach a Buyer Profile to it
 - create a Buyer Account and add it to the relevant Buyer Group
 - add Contact Point Addresses for Shipping and Billing to your new buyer Account
 - activate the store
 - publish your store so that the changes are reflected
 - build the search index for your store
 - set a password for the new Buyer User and display the user details (including user name and password)
 - setup Guest Browsing by default for B2C stores

7. Your new store is almost ready to go! Before you log in as the Buyer User, you need to perform these last steps manually:

- 7.1 Setting up Credit Card Authorization

By default, a mocked gateway (SalesforceAdapter) integration has been set up.  You can quickly set up another integration with Payeezy and/or Stripe by running:
```
./quickstart-setup-payments.sh <YourStoreName>
```

For further customizations to your gateway, see the documentation [here](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_commercepayments_adapter_intro.htm).  

- 7.2 Enable Guest Browsing

By default, Guest Browsing has been disabled for B2B stores but enabled in B2C stores. Even if Guest Browsing is currently disabled in your store, you can enable it by running 
```
./enable-guest-browsing.sh <YourStoreName> <NameOfBuyerGroup>
```

If you have used Quick Start to setup your store, the name of your Buyer Group will be "BUYERGROUP_FROM_QUICKSTART_1". 

## The `sfdx-project.json` File

The `sfdx-project.json` file contains useful configuration information for your project. See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) in the _Salesforce DX Developer Guide_ for details about this file.

The most important parts of this file for getting started are the `sfdcLoginUrl` and `packageDirectories` properties.

The `sfdcLoginUrl` specifies the default login URL to use when authorizing an org.

The `packageDirectories` filepath tells VS Code and Salesforce CLI where the metadata files for your project are stored. You need at least one package directory set in your file. The default setting is shown below. If you set the value of the `packageDirectories` property called `path` to `force-app`, by default your metadata goes in the `force-app` directory. If you want to change that directory to something like `src`, simply change the `path` value and make sure the directory you’re pointing to exists.
```json
"packageDirectories" : [
    {
      "path": "force-app",
      "default": true
    }
]
```
## Working with Source

For details about developing against scratch orgs, see the [Package Development Model](https://trailhead.salesforce.com/en/content/learn/modules/sfdx_dev_model) module on Trailhead or [Package Development Model with VS Code](https://forcedotcom.github.io/salesforcedx-vscode/articles/user-guide/package-development-model).

For details about developing against orgs that don’t have source tracking, see the [Org Development Model](https://trailhead.salesforce.com/content/learn/modules/org-development-model) module on Trailhead or [Org Development Model with VS Code](https://forcedotcom.github.io/salesforcedx-vscode/articles/user-guide/org-development-model).

## Deploying to Production

Don’t deploy your code to production directly from Visual Studio Code. The deploy and retrieve commands do not support transactional operations, which means that a deployment can fail in a partial state. Also, the deploy and retrieve commands don’t run the tests needed for production deployments. The push and pull commands are disabled for orgs that don’t have source tracking, including production orgs.

Deploy your changes to production using [packaging](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_dev2gp.htm) or by [converting your source](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_force_source.htm#cli_reference_convert) into metadata format and using the [metadata deploy command](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_force_mdapi.htm#cli_reference_deploy).

## More Information about what is installed

Once installed, you should be able actually take a cart through checkout as a buyer user. However, while the flow of the checkout functions, much of the important work is mocked. To see what was installed so you can determine what to update, you should go to the Examples directory and then navigate into the directories you care about. For instance, the *framework* directory contains all of the flows that control the flow of the checkout. The *integrations* directory is where you'll find Apex classes that can be updated to hook up to real systems to determine shipping and taxes.
