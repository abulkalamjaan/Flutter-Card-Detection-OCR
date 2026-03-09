## The Master Blueprint: CNIC OCR System

# Phase 1: Project Setup & Dependencies

# Goal: Initialize the Flutter environment and add necessary plugins.

# Action: Add google_mlkit_text_recognition, google_mlkit_document_scanner, and image_picker to pubspec.yaml.

# Action: Configure iOS Info.plist and Android AndroidManifest.xml for Camera and Gallery permissions.

# Phase 2: The Document Scanning Engine

# Goal: Create a reliable UI to capture the Front and Back images.

# Logic: Use DocumentScanner to ensure the image is cropped and the perspective is corrected (top-down view).

# Workflow:

# User clicks "Scan Front".

# Scanner returns a cropped .jpg.

# User clicks "Scan Back".

# Scanner returns a second .jpg.

# Phase 3: The Text Extraction Logic (The "Brain")

# Goal: Process the images and map the strings to a data model.

# Data Model: Create a CnicModel class with fields: name, fatherName, cnicNumber, dob, expiry, and address.

# Regex Extraction Strategy:

# CNIC: r"\d{5}-\d{7}-\d{1}"

Dates (DOB/Expiry): r"\d{2}.\d{2}.\d{4}"

Keywords: Search for "Name", "Father Name", and "Address". Since the name is usually below the label "Name", the logic should find the index of the label and grab the string at index + 1.

Phase 4: Address Processing (The Back Side)

Goal: Specific logic for the more complex back side of the card.

Logic: The address is usually the largest block of text. Use a loop to collect all lines after the keyword "Address" until a date or the bottom margin is reached.

Phase 5: User Verification UI

Goal: Allow the user to edit any OCR mistakes.

Action: Create a form pre-populated with the extracted data.

Validation: Ensure the CNIC number has exactly 13 digits and dates are in the past (DOB) or future (Expiry).