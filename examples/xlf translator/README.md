# xlf-translator
## Localize Store Labels in Bulk

When you add languages to Experience Builder, some component labels are translated for you into the selected language. If you add more languages, you can translate your store’s text elements in bulk by using the translation tool. You can also translate configurable labels manually in the component properties.

1. On your store’s home page, click **Website Design**, and then click **Experience Builder**.  
2. Click *![][image1]* and select **Languages**.  
3. Click **Add Languages** or **Edit Languages**, and choose which languages to make available for your store.  
4. Click **Export Content**.  
5. Select the language that you want to translate to, and click **Export**.  
6. From [GitHub](https://github.com/forcedotcom/b2b-commerce-on-lightning-quickstart/tree/master), click **Code**, and then click **Download ZIP**.  
7. To add translations for any custom text element, unzip the file and select **examples \-\> xlf translator \-\> mappings**, and add the translation to the corresponding mapping file.   
   For example, to translate **Hello World** in French, add these lines to the mappings\_fr.js file.

{

            source: "Hello World",

            target: "Bonjour le monde"

        },

8. To access the translation tool, unzip the file, and select **examples \-\> xlf translator \-\> engine \> index.html**.  
9. In the translation tool, click **Upload File**, upload the XLF file, and click **Translate**.  
   The XLF file is translated.  
10. Go to the Experience Builder Languages settings page and under Import Translated Content, click **Upload File** and upload your translated file.  
11. At the top of the navigation bar, click *\[Languages icon\]* and select the store’s language.  
    Your store is translated to the selected language.

    

    

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWCAYAAADAQbwGAAAB9UlEQVR4Xq1UiU4CMRDl/39CBMGDQ0W55JBLEISAB2pABcMlntySsDrySrou3WxJjC95yezM9G1nOq2J/hkm0SHi7aNPpesqI+xVkAr2ByPaPgjT2o6XETZ8MkgFa40OWVx+VRA2fDIYCo7GEwolz1QxzvhpkSafUzFdBRNEb5zeY7LtBimRLVH+4pasroBOjNPqDlCxXKFk7pw290Pk9sfUVpi+v4mOEjndIi033EH2M9GvJTbCBMXGaxmMZ1npHLDhE/NAly9G48l0scN0/pLMDp/uj4i1u68UTRcYYcOHmDYXazOFq8UO+d/LlQf1RLc8YXrvDeiu3lzqJWz4EEMOfFiDtRyqIA7GvnfEkryRNM0UhTyhpK40+BBDDr6xRjvwhoIYDZyeKAgfYisFMbC8PN5gjIUoCB9iyME3JqD19LIseFOts9nii9DkcqVGs5lCkVSe1p0+RtjwIaY9RNt8l7VGeyE4GI5p5zCq2wmS7h9b6p854ENMzOetMKHBvmhGl8DpCaUof37DCFuMc0ZPCmykWMmNdpc25jcBZaDZRsPLifIxu5hH9BDXlh+MeiiK8sXI0ew863Zkdixuj+xdNHxtAPTL4vx9vnBwqEYGqSBuhH3+mnBB3I5efyimLUEqiCZni2X2RG0fRJaumBGkgn/BD+WQGKXclgCmAAAAAElFTkSuQmCC>
