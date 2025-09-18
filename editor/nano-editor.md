# Complete Nano Editor Tutorial for Beginners

## Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Nano Basics](#nano-basics)
4. [Navigation](#navigation)
5. [Editing Text](#editing-text)
6. [Cut, Copy, and Paste](#cut-copy-and-paste)
7. [Search and Replace](#search-and-replace)
8. [File Operations](#file-operations)
9. [Configuration and Customization](#configuration-and-customization)
10. [YAML Editing for CKA Candidates](#yaml-editing-for-cka-candidates)
11. [Troubleshooting and Common Mistakes](#troubleshooting-and-common-mistakes)
12. [Practice Exercises](#practice-exercises)
13. [Quick Reference Card](#quick-reference-card)

---

## Introduction

**Nano** is a simple, user-friendly text editor available on most Linux/Unix systems. It is ideal for beginners due to its intuitive interface and helpful on-screen shortcuts. This tutorial will guide you through essential Nano commands and practical examples.

### Why Learn Nano?
- Easy to use, minimal learning curve
- On-screen command shortcuts
- Available on most Linux/Unix systems
- Great for quick edits and YAML/Kubernetes work

---

## Getting Started

### Opening Nano
```bash
# Open nano with a new file
nano filename.txt

# Open nano with an existing file
nano /path/to/existing/file.txt

# Open nano without a filename (can save later)
nano
```

### Exiting Nano
```
Ctrl+X      # Exit nano (prompts to save if changes made)
Y           # Yes, save changes
N           # No, discard changes
Ctrl+C      # Cancel exit, return to editor
```

---

## Nano Basics

Nano displays helpful shortcuts at the bottom of the screen. The `^` symbol means "Ctrl" (e.g., `^X` is Ctrl+X).

### Modes
- **Editing Mode**: Default, type to insert text
- **Command Mode**: Use Ctrl key combinations for commands

---

## Navigation

### Moving the Cursor
```
Arrow keys      # Move cursor up/down/left/right
Ctrl+A          # Move to beginning of line
Ctrl+E          # Move to end of line
Ctrl+Y          # Page up
Ctrl+V          # Page down
Ctrl+_          # Go to line and column (Ctrl+Shift+-)
```

### Example Navigation Practice
```bash
echo -e "Line 1\nLine 2\nLine 3\nLine 4\nLine 5" > practice.txt
nano practice.txt
# Use arrow keys to move between lines
# Try Ctrl+A and Ctrl+E to jump to line start/end
```

---

## Editing Text

### Inserting and Deleting
```
Type to insert text at cursor
Backspace/Delete    # Remove character before/under cursor
Ctrl+D              # Delete character under cursor
Ctrl+K              # Cut current line
Ctrl+U              # Uncut (paste) last cut text
```

### Undo and Redo
```
Ctrl+Z      # Undo last action
Ctrl+Shift+Z # Redo (if supported)
```

### Examples
```bash
# Open nano with a file: nano example.txt
# Type "Hello World" and use Backspace to correct typos
# Use Ctrl+K to cut a line, Ctrl+U to paste it elsewhere
```

---

## Cut, Copy, and Paste

### Cutting (Deleting)
```
Ctrl+K      # Cut current line
Ctrl+Shift+6 # Set mark (start selection)
Arrow keys   # Move to select text
Ctrl+K      # Cut selected text
```

### Copying
```
Ctrl+Shift+6 # Set mark
Arrow keys   # Select text
Alt+6        # Copy selected text
```

### Pasting
```
Ctrl+U      # Paste (uncut) text at cursor
```

### Examples
```bash
# Copy and paste lines:
# 1. Move to line to copy
# 2. Ctrl+Shift+6 to set mark, use arrows to select
# 3. Alt+6 to copy
# 4. Move to destination, Ctrl+U to paste
# 5. Ctrl+K to cut, Ctrl+U to paste
```

---

## Search and Replace

### Searching
```
Ctrl+W      # Search for text
Type pattern, Enter
Ctrl+W, Ctrl+Y # Repeat search backward
Ctrl+W, Ctrl+V # Repeat search forward
```

### Replacing
```
Ctrl+\      # Search and replace
Type search string, Enter
Type replacement, Enter
Y           # Replace this occurrence
A           # Replace all occurrences
N           # Skip this occurrence
```

### Examples
```bash
# Replace all "cat" with "dog":
# Ctrl+\, type "cat", Enter, type "dog", Enter, A
```

---

## File Operations

### Saving Files
```
Ctrl+O      # Write (save) file
Enter       # Confirm filename
Ctrl+X      # Exit nano
```

### Opening Files
```
nano filename.txt      # Open file
Ctrl+R                # Insert another file into current buffer
```

### Multiple Buffers
```
Ctrl+R      # Read file into current buffer
Ctrl+X      # Exit, prompts to save all buffers
```

### File Information
```
Ctrl+C      # Show current cursor position
Ctrl+G      # Show help (all commands)
```

### Examples
```bash
# Save as new name:
# Ctrl+O, type new filename, Enter
# Ctrl+X to exit
```

---

## Configuration and Customization

### Nano Settings (Temporary)
```
Alt+L      # Toggle line numbers
Alt+I      # Toggle auto-indent
Alt+S      # Toggle smooth scrolling
Alt+M      # Toggle mouse support
```

### Permanent Settings
Edit your `~/.nanorc` file to set options globally:
```bash
# Example ~/.nanorc
set linenumbers
set tabsize 2
set autoindent
set softwrap
set mouse
```

---

## YAML Editing for CKA Candidates

Nano is great for editing YAML files for Kubernetes. Here are tips for CKA exam:

### Essential YAML Concepts
- Use spaces, not tabs (Nano inserts spaces by default)
- Indentation matters for structure
- Key-value pairs: `key: value`
- Lists: items start with `-`

### Nano Setup for YAML
```bash
# Show line numbers: Alt+L
# Set tab size: add 'set tabsize 2' to ~/.nanorc
# Enable auto-indent: Alt+I or 'set autoindent' in ~/.nanorc
```

### Indenting Blocks
```
Tab        # Indent line right
Shift+Tab  # Unindent (if supported)
```

### Quick YAML Editing Techniques
```bash
# Duplicate a section:
# 1. Set mark (Ctrl+Shift+6), select block, Alt+6 to copy
# 2. Move to destination, Ctrl+U to paste

# Change values:
# Use arrow keys to move, type to overwrite

# Add environment variables:
# Move to correct line, Enter for new line, type 'env:'
```

### YAML Validation
```bash
# Check indentation visually with line numbers (Alt+L)
# Use kubectl to validate:
kubectl apply -f file.yaml --dry-run=client
```

---

## Troubleshooting and Common Mistakes

### 1. Accidentally Exiting Without Saving
**Solution**: Ctrl+X, then Y to save, Enter to confirm

### 2. Overwriting Files
**Solution**: Nano prompts before overwriting; check filename before saving

### 3. Losing Unsaved Changes
**Solution**: Always save (Ctrl+O) before exiting

### 4. Indentation Errors in YAML
**Solution**: Use line numbers (Alt+L), check spaces

### 5. Not Finding Commands
**Solution**: Ctrl+G for help menu

---

## Practice Exercises

### Exercise 1: Basic Navigation and Editing
```bash
echo -e "Apple\nBanana\nCherry\nDate\nElderberry" > fruits.txt
# Tasks:
# 1. Open the file in nano
# 2. Go to the third line (Cherry)
# 3. Change "Cherry" to "Coconut"
# 4. Add a new line after "Date" with "Fig"
# 5. Delete the last line
# 6. Save and exit
```

### Exercise 2: Cut, Copy, and Paste
```bash
echo -e "Line 1\nLine 2\nLine 3\nLine 4\nLine 5" > lines.txt
# Tasks:
# 1. Copy line 2 and paste it after line 4
# 2. Move line 1 to the end of the file
# 3. Duplicate the entire file content below the existing content
# 4. Save as "lines_modified.txt"
```

### Exercise 3: Search and Replace
```bash
echo "The quick brown fox jumps over the lazy dog. The fox is quick." > sentence.txt
# Tasks:
# 1. Replace all instances of "fox" with "cat"
# 2. Replace "quick" with "fast" only in the first occurrence
# 3. Search for "lazy" and replace it with "sleepy"
# 4. Save the file
```

### Exercise 4: Advanced Operations
```bash
cat > code.txt << 'EOF'
function hello() {
		console.log("Hello World");
}

function goodbye() {
		console.log("Goodbye World");
}
EOF
# Tasks:
# 1. Add line numbers (Alt+L)
# 2. Copy the entire hello function
# 3. Paste it after the goodbye function
# 4. Change the copied function name to "greeting"
# 5. Change the message to "Greetings World"
# 6. Save the file
```

### Exercise 5: YAML Editing for CKA (Kubernetes)
```bash
cat > deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
	name: web-app
	namespace: default
spec:
	replicas: 2
EOF
# Tasks:
# 1. Set up nano for YAML editing (Alt+L, tabsize 2, autoindent)
# 2. Change replicas from 2 to 5
# 3. Update nginx image version from 1.20 to 1.21
# 4. Add resource limits (memory: "128Mi", cpu: "500m")
# 5. Add environment variables section
# 6. Change namespace from "default" to "production"
# 7. Add a second container to the pod
# 8. Save the file
```

### Exercise 6: Multi-Resource YAML File
```bash
cat > app-stack.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
	name: myapp
---
apiVersion: apps/v1
kind: Deployment
metadata:
	name: frontend
	namespace: myapp
spec:
	replicas: 3
---
apiVersion: v1
kind: Service
metadata:
	name: frontend-service
	namespace: myapp
spec:
	selector:
		app: frontend
	type: ClusterIP
EOF
# Tasks:
# 1. Navigate between the three resources using search (Ctrl+W)
# 2. Change all image versions from 1.20 to 1.21
# 3. Add labels to all resources (environment: production)
# 4. Change the service type from ClusterIP to NodePort
# 5. Add nodePort: 30080 to the service
# 6. Copy the entire deployment and modify it for a "backend" service
# 7. Update selectors and labels accordingly
```

---

## Quick Reference Card

### Essential Commands
```
# Navigation
Arrow keys         # Move cursor
Ctrl+A / Ctrl+E    # Line start/end
Ctrl+Y / Ctrl+V    # Page up/down
Ctrl+_             # Go to line/column

# Editing
Type, Backspace, Delete
Ctrl+K             # Cut line
Ctrl+U             # Paste
Ctrl+Shift+6       # Set mark (select)
Alt+6              # Copy selection

# File Operations
Ctrl+O             # Save
Ctrl+X             # Exit
Ctrl+R             # Insert file

# Search/Replace
Ctrl+W             # Search
Ctrl+\             # Replace

# Help
Ctrl+G             # Show help

# Undo/Redo
Ctrl+Z             # Undo
Ctrl+Shift+Z       # Redo

# Line Numbers
Alt+L              # Toggle line numbers
```

### YAML/CKA Specific Commands
```
# YAML Setup
Alt+L               # Show line numbers
set tabsize 2       # ~/.nanorc for tab width
set autoindent      # ~/.nanorc for auto-indent

# Indentation
Tab / Shift+Tab     # Indent/unindent

# Kubernetes Navigation
Ctrl+W, type pattern # Search for apiVersion, kind, metadata, spec, containers

# Common CKA Edits
Type to overwrite values
Ctrl+K / Ctrl+U     # Cut/paste lines
Alt+6 / Ctrl+U      # Copy/paste blocks
Ctrl+O              # Save file
kubectl apply -f % --dry-run=client # Test YAML
```

Happy editing! 🚀
