# b2b-commerce-for-lightning

This repository has a set of useful reference implementations for the B2B Lightning projects. It is structured in 2 parts: examples and sfdx.

**WARNING!** By following the setup instructions for this tool (in the examples, as well as in the sfdx section), the sharing settings of your org will be updated! See in [this folder](examples/users/sharing-settings-setup) what sharing settings will be modified and how. In addition to those, the newly created user profiles (for buyer user and guest) will have the user permissions and CRUD access object permissions automatically updated.

The **examples** include metadata API sources that can help to setup a B2B project and provide examples for a quick start with this project. They can be deployed as described in the Salesforce documentation [here](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/file_based.htm). 
The **examples** contain 3 folders: 
1. **checkout**  covers information and instructions on how to deploy each of the components required to build a fully working checkout for a B2B Store. Flows are setup [here](examples/checkout/framework). Mock integrations are provided [here](examples/checkout/integrations). Notifications are provided [here](examples/checkout/notifications). 
2. [**diagnostic**](examples/diagnostic/commerce-diagnostic-event-setup) sets up a diagnostic workflow that allows you to debug issues that could occur during checkout of your store.
3. **users** covers how to deploy an org, a buyer user profile, and a guest user profile, with the settings required. Instructions on how to deploy a buyer profile for your B2B store [here](examples/users/buyer-user-profile-setup).
Instructions on how to deploy a guest user profile for your B2B store [here](examples/users/guest-user-profile-setup).
Sharing settings that need to be enabled are covered [here](examples/users/sharing-settings-setup). 

The **sfdx** section is aimed to the developers who use the SFDX environment. There are no source files in this section, they will be converted from the metadata format (in "examples") to the SFDX format by running the script in the sfdx directory. After the conversion to the SFDX format it is the developer's responsibility to maintain the files and continue working with them in the new SFDX project.
