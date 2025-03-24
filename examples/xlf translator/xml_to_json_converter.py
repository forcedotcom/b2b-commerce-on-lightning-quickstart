import json
import os
import html
from bs4 import BeautifulSoup

def clean_html(html_string):
    """
    Removes HTML and CSS tags from the provided source string, keeping only the plain text.
    """
    # First, unescape any HTML entities like &amp;lt; and &amp;gt; twice
    unescaped_string = html.unescape(html.unescape(html_string))
    
    # Parse the unescaped HTML using BeautifulSoup
    soup = BeautifulSoup(unescaped_string, 'lxml')
    
    # Get the text content, which strips all HTML tags
    clean_text = soup.get_text(separator=' ', strip=True)
    
    return clean_text

def main():
    # Specify the file name (for example, 'Japan_D2C-export.xlf')
    # file_name = 'Alpine_B2B_XLF.xlf'
    # file_name = 'Alpine_D2C_XLF.xlf'
    # file_name = 'Cirrus_B2B_XLF.xlf'
    file_name = 'Cirrus_D2C_XLF.xlf'

    # Read the content of the .xlf file
    with open(file_name, 'r') as file:
        text = file.read()
    
    result = []
    sources = set()

    for line in text.splitlines():
        if "<source>" not in line:
            continue
        line = line.lstrip(' ')
        
        start = 8
        end = len(line) - 9
        res = line[start:end]
        
        # Clean the source text by unescaping and removing HTML/CSS tags
        clean_res = clean_html(res)

        if sources.__contains__(clean_res):
            continue
        
        result.append({"source": clean_res, "target": ""})
        sources.add(clean_res)

    # Convert result to JSON
    json_converted = json.dumps({'mappings': result}, indent=4)

    # Generate the new file name with a .json extension
    json_file_name = os.path.splitext(file_name)[0] + '.json'

    # Save the JSON to a file in the same location
    with open(json_file_name, 'w') as json_file:
        json_file.write(json_converted)

    print(f"JSON saved as {json_file_name}")

if __name__ == "__main__":
    main()
