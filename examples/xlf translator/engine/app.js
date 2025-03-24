let uploadedFile;
let mappings = {}; // Will hold the mapping for the selected language

// Function to handle file selection
function fileSelected(event) {
    uploadedFile = event.target.files[0];
    if (uploadedFile) {
        const translateBtn = document.getElementById('translateBtn');
        translateBtn.disabled = false;
        translateBtn.classList.add('enabled');

        // Display the uploaded file name
        const fileInfoDiv = document.getElementById('fileInfo');
        fileInfoDiv.innerText = `Uploaded File: ${uploadedFile.name}`;
        fileInfoDiv.style.display = 'block';

        clearError();
    }
}

// Drag and drop functionality
const uploadBox = document.getElementById('uploadBox');

uploadBox.addEventListener('dragover', (event) => {
    event.preventDefault(); // Prevent default behavior (Prevent file from being opened)
    uploadBox.style.borderColor = '#007bff'; // Change border color on drag
});

uploadBox.addEventListener('dragleave', () => {
    uploadBox.style.borderColor = '#ccc'; // Reset border color
});

uploadBox.addEventListener('drop', (event) => {
    event.preventDefault();
    uploadBox.style.borderColor = '#ccc'; // Reset border color
    if (event.dataTransfer.files.length > 0) {
        uploadedFile = event.dataTransfer.files[0];
        const translateBtn = document.getElementById('translateBtn');
        translateBtn.disabled = false;
        translateBtn.classList.add('enabled');

        // Display the uploaded file name
        const fileInfoDiv = document.getElementById('fileInfo');
        fileInfoDiv.innerText = `Uploaded File: ${uploadedFile.name}`;
        fileInfoDiv.style.display = 'block';

        clearError();
    }
});

function translateFile() {
    if (!uploadedFile) return;

    const reader = new FileReader();
    reader.onload = function (e) {
        const xmlContent = e.target.result;
        const parser = new DOMParser();
        let xmlDoc;

        try {
            xmlDoc = parser.parseFromString(xmlContent, 'application/xml');
            const parserError = xmlDoc.getElementsByTagName('parsererror');
            if (parserError.length > 0) {
                throw new Error('Invalid XML format');
            }
        } catch (error) {
            return displayError('Error parsing XML: ' + error.message);
        }

        const trgLang = xmlDoc.documentElement.getAttribute('trgLang');
        if (!trgLang) {
            return displayError('Target language (trgLang) not specified in the .xlf file.');
        }

        // Load the appropriate mappings constant based on trgLang
        if (trgLang === 'ja') {
            mappings = MAPPINGS_JA.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'fr') {
            mappings = MAPPINGS_FR.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'es') {
            mappings = MAPPINGS_ES.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'es_MX') {
            mappings = MAPPINGS_ES_MX.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'zh_TW') {
            mappings = MAPPINGS_ZH_TW.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'zh_CN') {
            mappings = MAPPINGS_ZH_CN.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'th') {
            mappings = MAPPINGS_TH.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'sv') {
            mappings = MAPPINGS_SV.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'ru') {
            mappings = MAPPINGS_RU.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'pt_BR') {
            mappings = MAPPINGS_PT_BR.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'nl_NL') {
            mappings = MAPPINGS_NL_NL.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'no') {
            mappings = MAPPINGS_NO.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'ko') {
            mappings = MAPPINGS_KO.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'it') {
            mappings = MAPPINGS_IT.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'fi') {
            mappings = MAPPINGS_FI.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'de') {
            mappings = MAPPINGS_DE.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else if (trgLang === 'da') {
            mappings = MAPPINGS_DA.mappings.reduce((acc, mapping) => {
                acc[mapping.source] = mapping.target;
                return acc;
            }, {});
        } else {
            return displayError(`No mapping found for language: ${trgLang}`);
        }

        // Perform the translation
        translateXML(xmlDoc);

        // Serialize the updated XML
        const serializer = new XMLSerializer();
        const updatedXmlStr = serializer.serializeToString(xmlDoc);

        // Trigger download
        downloadTranslatedFile(updatedXmlStr);
        setTimeout(() => {
            // Hide the upload screen and show the success screen
            document.getElementById('uploadScreen').style.display = 'none';
            document.getElementById('successScreen').style.display = 'flex';
        }, 500); // Simulate a delay for translation
    };

    reader.onerror = function () {
        displayError('Error reading the file: ' + reader.error);
    };

    reader.readAsText(uploadedFile);
}


function translateXML(xmlDoc) {
    const xliffNS = 'urn:oasis:names:tc:xliff:document:2.0';
    const unitElements = xmlDoc.getElementsByTagNameNS(xliffNS, 'unit');

    for (let i = 0; i < unitElements.length; i++) {
        const unit = unitElements[i];
        const segment = unit.getElementsByTagNameNS(xliffNS, 'segment')[0];
        const source = segment.getElementsByTagNameNS(xliffNS, 'source')[0];
        let target = segment.getElementsByTagNameNS(xliffNS, 'target')[0];

        let sourceText = source.textContent.trim();
        let targetText = '';

        // Handle HTML-like content
        if (isHTML(sourceText)) {
            targetText = processTextWithMappings(sourceText, mappings);
            target.textContent = targetText;
        }
        else if (hasChildElements(source)) {
            let sourceString = source.innerHTML;
            targetText = processTextWithMappings(sourceString, mappings);
            target.innerHTML = targetText;
        }
        // Handle JSON-like content
        else if (source.textContent.trim().startsWith('{') && source.textContent.trim().endsWith('}') &&
            isJSON(source.textContent.trim())) {
            try {
                let jsonObject = JSON.parse(source.textContent.trim());
                if (jsonObject.imageInfoV1 && jsonObject.imageInfoV1.altText) {
                    const originalAltText = jsonObject.imageInfoV1.altText;
                    jsonObject.imageInfoV1.altText = mappings[originalAltText] || originalAltText;
                }
                targetText = JSON.stringify(jsonObject).replace(/\\/g, '\\\\');
                target.textContent = targetText;
            } catch (error) {
                console.error('JSON parsing error', error);
            }
        }
        // Regular text translation
        else {
            sourceText = source.textContent.trim(); // Get plain text (without tags)
            targetText = mappings[sourceText] || sourceText;
            target.textContent = targetText;
        }

        if (!target) {
            target = xmlDoc.createElementNS(xliffNS, 'target');
            segment.appendChild(target);
        }
    }
}

function processTextWithMappings(sourceString, mappings) {
    let updatedText = sourceString;
    const htmlDecoded = decodeHTML(sourceString); // Decode entities like &lt; and &gt; to < and >

    // Extract the translatable text and replace it in the original source
    const extractedTexts = extractTranslatableTexts(htmlDecoded);
    extractedTexts.forEach(text => {
        const translatedText = mappings[text.trim()] || text.trim();
        const translatedWithSpaces = retainSpaces(text, translatedText); // Retain leading/trailing spaces
        updatedText = updatedText.replace(text, translatedWithSpaces);
    });

    return updatedText;
}


// Function to check if the source has any child elements (HTML-like content)
function hasChildElements(element) {
    return element.children.length > 0;
}

// Function to decode HTML entities like &lt; and &gt; back to < and >
function decodeHTML(html) {
    const txt = document.createElement('textarea');
    txt.innerHTML = html;
    return txt.value;
}

// Function to extract multiple translatable texts (for HTML-like content)
function extractTranslatableTexts(sourceText) {
    // Matches all text segments between HTML tags or encoded HTML tags
    const regex = />([^<]+)</g;
    const matches = [...sourceText.matchAll(regex)];
    return matches.map(match => match[1]); // Return array of text strings
}

// Function to retain leading/trailing spaces in translated text
function retainSpaces(originalText, translatedText) {
    const leadingSpace = originalText.startsWith(' ') ? ' ' : '';
    const trailingSpace = originalText.endsWith(' ') ? ' ' : '';
    return leadingSpace + translatedText + trailingSpace;
}

function isHTML(string) {
    // Check if the string contains any common HTML tags or encoded HTML entities
    return /<[^>]+>/.test(string) || string.includes("&lt;") || string.includes("&gt;");
}

function downloadTranslatedFile(content) {
    const blob = new Blob([content], { type: 'application/xml' });
    const url = URL.createObjectURL(blob);

    const a = document.createElement('a');
    a.href = url;
    a.download = uploadedFile.name.replace('.xlf', '-translated.xlf');
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
}

function displayError(message) {
    const errorMessageDiv = document.getElementById('errorMessage');
    errorMessageDiv.innerText = message;
    errorMessageDiv.style.display = 'block';
}

function clearError() {
    const errorMessageDiv = document.getElementById('errorMessage');
    errorMessageDiv.innerText = '';
    errorMessageDiv.style.display = 'none';
}

function startOver() {
    // Reset the UI
    document.getElementById('fileUpload').value = ''; // Clear file input
    document.getElementById('fileInfo').style.display = 'none'; // Hide file info
    document.getElementById('translateBtn').disabled = true; // Disable translate button
    document.getElementById('translateBtn').classList.remove('enabled'); // Remove button enabled class

    // Switch back to the upload screen
    document.getElementById('successScreen').style.display = 'none';
    document.getElementById('uploadScreen').style.display = 'flex';
}

function isJSON(input) {
    try {
        const parsed = JSON.parse(input);
        return typeof parsed === 'object' && parsed !== null;
    } catch (e) {
        return false;
    }
}