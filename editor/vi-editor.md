# Complete Vi Editor Tutorial for Beginners

## Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Vi Modes](#vi-modes)
4. [Basic Navigation](#basic-navigation)
5. [Entering Text](#entering-text)
6. [Editing Commands](#editing-commands)
7. [Copy, Cut, and Paste](#copy-cut-and-paste)
8. [Line Operations](#line-operations)
9. [Search and Replace](#search-and-replace)
10. [File Operations](#file-operations)
11. [Advanced Tips](#advanced-tips)
12. [YAML Editing for CKA Candidates](#yaml-editing-for-cka-candidates)
13. [Common Mistakes](#common-mistakes)
14. [Practice Exercises](#practice-exercises)

---

## Introduction

**Vi** (Visual Editor) is a powerful text editor that comes pre-installed on most Linux/Unix systems. While it may seem intimidating at first, mastering vi will make you incredibly efficient at text editing. This tutorial will guide you through all essential commands with practical examples.

### Why Learn Vi?
- Available on virtually every Linux/Unix system
- Very fast and lightweight
- Powerful editing capabilities
- Works over SSH connections
- No mouse required - keyboard-only operation

---

## Getting Started

### Setting Up Your Environment (CKA Tip)

Before diving into vi, here's a useful setup tip for CKA candidates:

#### Adding kubectl Alias to Zsh
Add this alias to your `~/.zshrc` file to save time during the exam:

```bash
# Edit your zsh configuration
vi ~/.zshrc

# Add this line to the file:
alias k=kubectl

# Save and reload your configuration
source ~/.zshrc

# Now you can use 'k' instead of 'kubectl':
k get pods
k get ds    # Instead of kubectl get daemonsets
k apply -f deployment.yaml
```

#### Other Useful Aliases for CKA
```bash
# Add these to ~/.zshrc for faster CKA exam workflow:
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployment'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
alias kdes='kubectl describe'

# Enable kubectl autocompletion
source <(kubectl completion zsh)
```

### Opening Vi
```bash
# Open vi with a new file
vi filename.txt

# Open vi with an existing file
vi /path/to/existing/file.txt

# Open vi without a filename (can save later)
vi
```

### Exiting Vi
Before we dive deep, here's how to exit vi (most important for beginners!):

```
:q          # Quit (only works if no changes made)
:q!         # Quit without saving changes (force quit)
:wq         # Write (save) and quit
:x          # Save and exit (same as :wq)
ZZ          # Save and exit (command mode shortcut)
```

---

## Vi Modes

Vi has three main modes:

### 1. Command Mode (Default)
- Used for navigation and text manipulation
- Cannot insert text directly
- All commands are executed immediately
- This is the mode vi starts in

### 2. Insert Mode
- Used for typing/inserting text
- Text appears as you type
- Press `Esc` to return to command mode

### 3. Command-Line Mode
- Used for file operations and advanced commands
- Accessed by typing `:` in command mode
- Commands appear at the bottom of the screen

### Mode Indicators
```
Command Mode:    No indicator (default)
Insert Mode:     -- INSERT -- (at bottom)
Command-Line:    : (cursor at bottom)
```

---

## Basic Navigation

### Moving the Cursor (Command Mode)

#### Basic Movement
```
h    # Move left (←)
j    # Move down (↓)
k    # Move up (↑)
l    # Move right (→)

# Alternative: Arrow keys also work
```

#### Word Movement
```
w    # Move to beginning of next word
W    # Move to beginning of next WORD (ignores punctuation)
b    # Move to beginning of previous word
B    # Move to beginning of previous WORD
e    # Move to end of current word
E    # Move to end of current WORD
```

#### Line Movement
```
0    # Move to beginning of line
^    # Move to first non-whitespace character
$    # Move to end of line
```

#### Screen Movement
```
H    # Move to top of screen (High)
M    # Move to middle of screen (Middle)
L    # Move to bottom of screen (Low)

Ctrl+f    # Page forward (Page Down)
Ctrl+b    # Page backward (Page Up)
Ctrl+d    # Half page down
Ctrl+u    # Half page up
```

#### File Movement
```
gg   # Go to first line of file
G    # Go to last line of file
:n   # Go to line number n (e.g., :15 goes to line 15)
```

### Example Navigation Practice
```
# Create a practice file
echo -e "Line 1\nLine 2\nLine 3\nLine 4\nLine 5" > practice.txt
vi practice.txt

# Try these movements:
# 1. Press 'j' three times to move down
# 2. Press 'k' once to move up
# 3. Press '0' to go to beginning of line
# 4. Press '$' to go to end of line
# 5. Press 'gg' to go to first line
# 6. Press 'G' to go to last line
```

---

## Entering Text

### Entering Insert Mode
```
i    # Insert before cursor
I    # Insert at beginning of line
a    # Append after cursor
A    # Append at end of line
o    # Open new line below cursor
O    # Open new line above cursor
```

### Examples
```bash
# Example 1: Adding text at cursor position
# 1. Open vi with a file: vi example.txt
# 2. Type 'i' to enter insert mode
# 3. Type: "Hello World"
# 4. Press Esc to return to command mode
# 5. Type ':wq' to save and exit

# Example 2: Adding new lines
# 1. Position cursor anywhere in text
# 2. Press 'o' to create new line below
# 3. Type your text
# 4. Press Esc when done
```

---

## Editing Commands

### Deleting Text (Command Mode)

#### Character Deletion
```
x    # Delete character under cursor
X    # Delete character before cursor
```

#### Word Deletion
```
dw   # Delete word from cursor position
dW   # Delete WORD from cursor position
db   # Delete word backward
```

#### Line Deletion
```
dd   # Delete entire current line
D    # Delete from cursor to end of line
d0   # Delete from cursor to beginning of line
```

#### Multiple Deletions
```
3dd  # Delete 3 lines starting from current line
5x   # Delete 5 characters
2dw  # Delete 2 words
```

### Changing Text
```
cw   # Change word (deletes word and enters insert mode)
cc   # Change entire line
C    # Change from cursor to end of line
s    # Substitute character (delete char and enter insert mode)
S    # Substitute line (delete line and enter insert mode)
r    # Replace single character (stays in command mode)
R    # Replace mode (overwrite text)
```

### Examples
```bash
# Example: Correcting a typo
# Original text: "Helo World"
# 1. Position cursor on 'e' in "Helo"
# 2. Press 'x' to delete 'e'
# 3. Press 'i' to enter insert mode
# 4. Type 'll' to make it "Hello"
# 5. Press Esc

# Example: Changing a word
# Original text: "The cat is sleeping"
# 1. Position cursor on 'c' in "cat"
# 2. Press 'cw' to change word
# 3. Type "dog" to replace it
# 4. Press Esc
```

---

## Copy, Cut, and Paste

### Understanding Registers
Vi uses "registers" (like clipboard) to store copied/cut text. The default register is unnamed.

### Yanking (Copying)
```
yy   # Yank (copy) current line
Y    # Yank current line (same as yy)
yw   # Yank word
y$   # Yank from cursor to end of line
y0   # Yank from cursor to beginning of line
```

### Cutting (Delete and Store)
```
dd   # Cut current line
dw   # Cut word
d$   # Cut from cursor to end of line
```

### Pasting
```
p    # Paste after cursor/below current line
P    # Paste before cursor/above current line
```

### Multiple Operations
```
3yy  # Copy 3 lines
5dd  # Cut 5 lines
2p   # Paste 2 times
```

### Examples
```bash
# Example 1: Copying and pasting lines
# 1. Position cursor on line you want to copy
# 2. Press 'yy' to copy the line
# 3. Move to where you want to paste
# 4. Press 'p' to paste below or 'P' to paste above

# Example 2: Moving text (cut and paste)
# 1. Position cursor on line to move
# 2. Press 'dd' to cut the line
# 3. Move to destination
# 4. Press 'p' to paste

# Example 3: Duplicating a word
# 1. Position cursor at beginning of word
# 2. Press 'yw' to copy word
# 3. Move cursor to destination
# 4. Press 'p' to paste
```

---

## Line Operations

### Line Numbers
```
:set number     # Show line numbers
:set nonumber   # Hide line numbers
:set nu         # Short form for number
:set nonu       # Short form for nonumber
```

### Moving Lines
```
:m n     # Move current line to after line n
:m 0     # Move current line to beginning of file
:m $     # Move current line to end of file
```

### Joining Lines
```
J    # Join current line with next line
3J   # Join current line with next 2 lines (3 total)
```

### Working with Line Ranges
```
:1,5d       # Delete lines 1 through 5
:10,15y     # Copy lines 10 through 15
:.,+5d      # Delete current line and next 5 lines
:%d         # Delete all lines in file
```

### Examples
```bash
# Example 1: Numbering lines and going to specific line
# 1. Open vi with a file
# 2. Type ':set number' and press Enter
# 3. Type ':15' and press Enter to go to line 15

# Example 2: Moving a line
# Original file:
# Line 1
# Line 2
# Line 3
# Line 4

# To move "Line 2" after "Line 4":
# 1. Position cursor on Line 2
# 2. Type ':m 4' and press Enter

# Example 3: Joining lines
# Original:
# Hello
# World
# 1. Position cursor on "Hello" line
# 2. Press 'J' to join with next line
# Result: "Hello World"
```

---

## Search and Replace

### Searching
```
/pattern     # Search forward for pattern
?pattern     # Search backward for pattern
n            # Next occurrence (same direction)
N            # Previous occurrence (opposite direction)
*            # Search forward for word under cursor
#            # Search backward for word under cursor
```

### Search Options
```
/pattern/i   # Case-insensitive search
/\<word\>    # Search for whole word only
```

### Replace (Substitute)
```
:s/old/new/         # Replace first occurrence in current line
:s/old/new/g        # Replace all occurrences in current line
:%s/old/new/        # Replace first occurrence in each line of file
:%s/old/new/g       # Replace all occurrences in entire file
:%s/old/new/gc      # Replace all with confirmation
:1,10s/old/new/g    # Replace all in lines 1-10
```

### Examples
```bash
# Example 1: Finding and replacing text
# File content: "The cat sat on the mat"
# To replace "cat" with "dog":
# 1. Type ':%s/cat/dog/g' and press Enter
# Result: "The dog sat on the mat"

# Example 2: Case-sensitive vs case-insensitive search
# To find "Hello" (any case):
# 1. Type '/hello/i' and press Enter (finds Hello, HELLO, hello)

# Example 3: Interactive replace
# To replace "old" with "new" with confirmation:
# 1. Type ':%s/old/new/gc' and press Enter
# 2. For each occurrence, press:
#    - y (yes, replace)
#    - n (no, skip)
#    - a (replace all remaining)
#    - q (quit)
```

---

## File Operations

### Saving Files
```
:w              # Write (save) file
:w filename     # Save as new filename
:w!             # Force write (overwrite read-only)
```

### Opening Files
```
:e filename     # Edit new file (closes current)
:e!             # Reload current file (lose changes)
```

### Multiple Files
```
:split filename    # Open file in horizontal split
:vsplit filename   # Open file in vertical split
Ctrl+w w          # Switch between windows
Ctrl+w q          # Close current window
```

### File Information
```
:f              # Show filename and position
Ctrl+g          # Show file status
:pwd            # Show current directory
```

### Examples
```bash
# Example 1: Saving with a new name
# 1. Edit your file
# 2. Type ':w backup.txt' to save a copy
# 3. Type ':w' to save original file

# Example 2: Working with multiple files
# 1. Open first file: vi file1.txt
# 2. Split window: :split file2.txt
# 3. Switch between windows: Ctrl+w w
# 4. Close window: Ctrl+w q
```

---

## Advanced Tips

### Undo and Redo
```
u        # Undo last change
U        # Undo all changes to current line
Ctrl+r   # Redo (undo the undo)
```

### Repeating Commands
```
.        # Repeat last command
@@       # Repeat last ex command (:command)
```

### Marks and Jumping
```
ma       # Set mark 'a' at current position
'a       # Jump to mark 'a'
''       # Jump back to previous position
```

### Visual Mode
```
v        # Visual mode (character selection)
V        # Visual line mode (line selection)
Ctrl+v   # Visual block mode (column selection)
```

### Macros
```
qa       # Start recording macro in register 'a'
q        # Stop recording
@a       # Execute macro 'a'
@@       # Repeat last macro
```

### Examples
```bash
# Example 1: Using visual mode to copy multiple lines
# 1. Position cursor at start of text
# 2. Press 'V' to enter visual line mode
# 3. Use 'j' or 'k' to select lines
# 4. Press 'y' to copy selected lines
# 5. Move to destination and press 'p' to paste

# Example 2: Creating a simple macro
# To add "TODO: " at the beginning of multiple lines:
# 1. Position cursor at beginning of first line
# 2. Press 'qa' to start recording macro 'a'
# 3. Press 'I' to insert at beginning of line
# 4. Type "TODO: "
# 5. Press Esc to return to command mode
# 6. Press 'j' to move to next line
# 7. Press 'q' to stop recording
# 8. Press '@a' to repeat on other lines
```

---

## YAML Editing for CKA Candidates

As a CKA exam candidate, you'll frequently work with Kubernetes YAML manifests. This section covers vi techniques specifically useful for YAML editing and Kubernetes resource management.

### YAML Basics in Vi

#### Essential YAML Concepts for CKA
- **Indentation**: YAML uses spaces (not tabs) for structure
- **Key-Value Pairs**: `key: value`
- **Lists**: Items start with `-`
- **Nested Objects**: Indicated by indentation
- **Comments**: Start with `#`

### Vi Configuration for YAML

#### Temporary YAML Settings (During Exam)
```
:set tabstop=2        # Set tab width to 2 spaces
:set shiftwidth=2     # Set indent width to 2 spaces
:set expandtab        # Convert tabs to spaces
:set autoindent       # Auto-indent new lines
:set number           # Show line numbers for reference
```

#### Quick YAML Setup Command
```
:set ts=2 sw=2 et ai nu
```

### Indentation Management

#### Indenting Blocks
```
>>       # Indent current line right
<<       # Indent current line left
3>>      # Indent 3 lines right
5<<      # Indent 5 lines left
```

#### Visual Mode Indentation
```
# Select multiple lines and indent:
V        # Enter visual line mode
j j j    # Select 3 lines
>        # Indent selected lines right
<        # Indent selected lines left
```

#### Re-indenting Entire Files
```
gg=G     # Re-indent entire file (auto-format)
=}       # Re-indent current block
```

### Working with Kubernetes Manifests

#### Common Kubernetes Resource Templates

##### Pod Template
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  namespace: default
  labels:
    app: my-app
spec:
  containers:
  - name: container-name
    image: nginx:latest
    ports:
    - containerPort: 80
    env:
    - name: ENV_VAR
      value: "value"
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

##### Deployment Template
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: container-name
        image: nginx:latest
        ports:
        - containerPort: 80
```

##### Service Template
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
```

### Quick YAML Editing Techniques

#### 1. Duplicating and Modifying Sections
```bash
# Example: Creating multiple containers
# 1. Position cursor on container definition line
# 2. Use visual mode to select entire container block:
V        # Enter visual line mode
}        # Go to end of block (or manually select)
y        # Copy the block
p        # Paste below

# 3. Modify the pasted container (name, image, etc.)
```

#### 2. Changing Values Quickly
```bash
# Example: Changing image versions
# Original: image: nginx:1.20
# 1. Position cursor on "1.20"
# 2. Press 'cw' to change word
# 3. Type new version "1.21"
# 4. Press Esc

# Example: Changing replica count
# Original: replicas: 3
# 1. Position cursor on "3"
# 2. Press 'r5' to replace with "5"
```

#### 3. Adding Environment Variables
```bash
# To add env vars to existing container:
# 1. Position cursor after 'ports:' section
# 2. Press 'o' to create new line
# 3. Type the env section:
    env:
    - name: NEW_VAR
      value: "new_value"
```

### YAML-Specific Search and Replace

#### Common CKA Replacements
```bash
# Change namespace across file
:%s/namespace: default/namespace: production/g

# Update image versions
:%s/nginx:1.20/nginx:1.21/g

# Change resource requests
:%s/memory: "64Mi"/memory: "128Mi"/g

# Update replica counts
:%s/replicas: 3/replicas: 5/g

# Change service types
:%s/type: ClusterIP/type: NodePort/g
```

#### Finding Specific YAML Sections
```bash
/apiVersion     # Find API version declarations
/kind:          # Find resource kinds
/metadata:      # Find metadata sections
/spec:          # Find spec sections
/containers:    # Find container definitions
/env:           # Find environment variables
/resources:     # Find resource definitions
```

### Managing Multiple YAML Documents

#### Working with Multi-Document Files
```bash
# YAML files can contain multiple documents separated by ---
# Navigate between documents:
/^---        # Find document separators
n            # Next occurrence
N            # Previous occurrence
```

#### Splitting Single File into Multiple Files
```bash
# To extract a document from multi-doc file:
# 1. Position cursor at start of document
# 2. Mark the position: ma
# 3. Go to end of document (before next ---)
# 4. Select the range: :'a,.w new-file.yaml
```

### CKA Exam-Specific Tips

#### 1. Quick Resource Generation
```bash
# Instead of writing from scratch, use kubectl to generate base YAML:
# kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment.yaml
# Then edit with vi
```

#### 2. Fast Label and Selector Editing
```bash
# Common pattern: Update labels and selectors together
# 1. Search for label: /app:
# 2. Change the value: cw new-app-name
# 3. Search for matching selector: /app:
# 4. Repeat the change: .
```

#### 3. Resource Quota and Limits
```bash
# Quickly add resource limits:
# Position after 'image:' line, press 'o' and add:
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

#### 4. ConfigMap and Secret References
```bash
# Adding configMap volume:
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
      volumes:
      - name: config-volume
        configMap:
          name: my-config

# Adding secret as env var:
        env:
        - name: SECRET_PASSWORD
          valueFrom:
            secretKeyRef:
              name: my-secret
              key: password
```

### YAML Validation Techniques

#### 1. Basic Syntax Checking
```bash
# Check indentation alignment
:set list           # Show whitespace characters
:set listchars=tab:>-,trail:-,extends:>,precedes:<
```

#### 2. Common YAML Errors to Avoid
- **Mixing tabs and spaces**: Use `:set expandtab` to prevent
- **Incorrect indentation**: Use visual selection and `>` or `<`
- **Missing colons**: Search for keys without colons `/^[[:space:]]*[^:]*$`
- **Trailing spaces**: Remove with `:%s/[[:space:]]\+$//g`

### Advanced YAML Editing Macros

#### Macro 1: Add Label to Multiple Resources
```bash
# Record macro to add a label:
qa                  # Start recording macro 'a'
/metadata:          # Find metadata section
j                   # Go to next line
o                   # Create new line
^                   # Go to beginning
i    environment: production    # Add label with proper indentation
^[                  # Press Esc
q                   # Stop recording

# Use macro:
@a                  # Apply to current resource
@@                  # Repeat last macro
```

#### Macro 2: Convert ClusterIP to NodePort
```bash
# Record macro:
qb                  # Start recording macro 'b'
/type: ClusterIP    # Find service type
cw                  # Change word
NodePort            # New type
^[                  # Press Esc
o                   # New line
  nodePort: 30080   # Add nodePort
^[                  # Press Esc
q                   # Stop recording
```

### CKA Exam Time-Saving Commands

#### Quick Reference for Exam
```bash
# Set up vi for YAML quickly
:set ts=2 sw=2 et ai nu

# Navigate to specific sections quickly
/kind:              # Find resource type
/metadata:          # Find metadata
/spec:              # Find specification
/containers:        # Find containers

# Quick edits
cw                  # Change word (values)
>>                  # Indent line right
<<                  # Indent line left
dd                  # Delete line
yy                  # Copy line
p                   # Paste

# Save and test
:w                  # Save file
:!kubectl apply -f % --dry-run=client    # Test without applying
```

#### Creating Persistent Volume Claims
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
```

#### Creating Ingress Resources
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

### Troubleshooting YAML in Vi

#### Common Issues and Solutions

1. **Indentation Errors**
   ```bash
   # Fix all indentation:
   gg=G
   
   # Check for tabs:
   /\t
   
   # Replace tabs with spaces:
   :%s/\t/  /g
   ```

2. **Missing or Extra Spaces**
   ```bash
   # Remove trailing spaces:
   :%s/[[:space:]]\+$//g
   
   # Ensure proper spacing after colons:
   :%s/:[[:space:]]\+/ /g
   ```

3. **Duplicate Keys**
   ```bash
   # Search for duplicate keys in metadata:
   /^\s*name:
   n n n    # Keep pressing 'n' to find duplicates
   ```

#### YAML Syntax Highlighting
```bash
# Enable syntax highlighting (if available):
:syntax on
:set filetype=yaml
```

### Practice Exercises for CKA

#### Exercise 1: Create a Complete Application Stack
```bash
# Create a file: vi webapp-stack.yaml
# Include:
# 1. Namespace
# 2. Deployment with 3 replicas
# 3. Service (ClusterIP)
# 4. ConfigMap
# 5. Secret
```

#### Exercise 2: Modify Existing Resources
```bash
# Given a deployment, modify it to:
# 1. Change replica count from 3 to 5
# 2. Update image version
# 3. Add resource limits
# 4. Add environment variables from configMap
# 5. Add a new container to the pod
```

#### Exercise 3: Quick Troubleshooting
```bash
# Given a broken YAML file with:
# - Wrong indentation
# - Missing colons
# - Incorrect API versions
# Fix all issues using vi commands
```

---

## Common Mistakes

### 1. Forgetting Which Mode You're In
**Problem**: Typing commands in insert mode or text in command mode
**Solution**: Always press `Esc` to ensure you're in command mode before entering commands

### 2. Accidentally Recording Macros
**Problem**: Typing 'q' followed by a letter starts macro recording
**Solution**: Press 'q' again to stop recording, or complete the macro and don't use it

### 3. Case Sensitivity
**Problem**: Commands are case-sensitive (G vs g, D vs d)
**Solution**: Pay attention to capitalization in commands

### 4. Not Saving Work
**Problem**: Exiting without saving changes
**Solution**: Use `:wq` to save and quit, or `:q!` if you intentionally want to discard changes

### 5. Getting Stuck in Ex Mode
**Problem**: Accidentally typing 'Q' enters Ex mode
**Solution**: Type 'vi' or 'visual' to return to normal vi mode

---

## Practice Exercises

### Exercise 1: Basic Navigation and Editing
```bash
# Create a practice file
echo -e "Apple\nBanana\nCherry\nDate\nEldberry" > fruits.txt

# Tasks:
# 1. Open the file in vi
# 2. Go to the third line (Cherry)
# 3. Change "Cherry" to "Coconut"
# 4. Add a new line after "Date" with "Fig"
# 5. Delete the last line
# 6. Save and exit
```

### Exercise 2: Copy, Cut, and Paste
```bash
# Create a practice file
echo -e "Line 1\nLine 2\nLine 3\nLine 4\nLine 5" > lines.txt

# Tasks:
# 1. Copy line 2 and paste it after line 4
# 2. Move line 1 to the end of the file
# 3. Duplicate the entire file content below the existing content
# 4. Save as "lines_modified.txt"
```

### Exercise 3: Search and Replace
```bash
# Create a practice file
echo "The quick brown fox jumps over the lazy dog. The fox is quick." > sentence.txt

# Tasks:
# 1. Replace all instances of "fox" with "cat"
# 2. Replace "quick" with "fast" only in the first occurrence
# 3. Search for "lazy" and replace it with "sleepy"
# 4. Save the file
```

### Exercise 4: Advanced Operations
```bash
# Create a practice file with code
cat > code.txt << 'EOF'
function hello() {
    console.log("Hello World");
}

function goodbye() {
    console.log("Goodbye World");
}
EOF

# Tasks:
# 1. Add line numbers to see the structure
# 2. Copy the entire hello function
# 3. Paste it after the goodbye function
# 4. Change the copied function name to "greeting"
# 5. Change the message to "Greetings World"
# 6. Save the file
```

### Exercise 5: YAML Editing for CKA (Kubernetes)
```bash
# Create a practice Kubernetes deployment file
cat > deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web-container
        image: nginx:1.20
        ports:
        - containerPort: 80
EOF

# Tasks:
# 1. Set up vi for YAML editing (:set ts=2 sw=2 et ai nu)
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
# Create a file with multiple Kubernetes resources
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
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: web
        image: nginx:1.20
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: myapp
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Tasks:
# 1. Navigate between the three resources using search
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
h j k l          # Arrow key movements
w b              # Word forward/backward
0 $              # Beginning/end of line
gg G             # First/last line of file

# Insert Mode
i a o            # Insert, append, open line
I A O            # Insert at line start, append at line end, open line above

# Editing
x dd dw          # Delete character, line, word
yy yw p P        # Copy line, word, paste after/before
u Ctrl+r         # Undo, redo

# File Operations
:w :q :wq        # Save, quit, save and quit
:q!              # Quit without saving

# Search
/text n N        # Search forward, next, previous
:%s/old/new/g    # Replace all occurrences
```

### YAML/CKA Specific Commands
```
# YAML Setup
:set ts=2 sw=2 et ai nu    # Configure for YAML editing

# Indentation
>> <<            # Indent/unindent line
V > <            # Visual mode indent/unindent
gg=G             # Re-indent entire file

# Kubernetes Navigation
/apiVersion      # Find API version
/kind:           # Find resource kind
/metadata:       # Find metadata section
/spec:           # Find spec section
/containers:     # Find containers

# Common CKA Edits
:%s/replicas: 3/replicas: 5/g           # Change replica count
:%s/nginx:1.20/nginx:1.21/g             # Update image version
:%s/namespace: default/namespace: prod/g # Change namespace
/^---            # Navigate between YAML documents

# Quick Resource Additions
o                # Add new line for resources/env vars
cw               # Change values quickly
r                # Replace single character (numbers)
```

---

## Configuration Tips

### Creating a .vimrc file
Create a `~/.vimrc` file to customize vi behavior:

```bash
# Basic .vimrc content
set number          " Show line numbers
set tabstop=4       " Set tab width to 4 spaces
set shiftwidth=4    " Set indent width to 4 spaces
set expandtab       " Convert tabs to spaces
set hlsearch        " Highlight search results
set ignorecase      " Case-insensitive search
set smartcase       " Case-sensitive if uppercase used
syntax on           " Enable syntax highlighting

# YAML-specific settings for CKA candidates
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType yaml setlocal autoindent
autocmd FileType yaml setlocal cursorcolumn  " Show column alignment
set listchars=tab:>-,trail:-,extends:>,precedes:<

# Kubernetes-friendly settings
set backspace=indent,eol,start  " Better backspace behavior
set ruler                       " Show cursor position
set showmatch                   " Highlight matching brackets
set incsearch                   " Incremental search
set wildmenu                    " Enhanced command completion
```

### CKA Exam-Ready .vimrc
For CKA exam preparation, use this optimized configuration:

```bash
# Minimal .vimrc for CKA exam
set number
set expandtab
set tabstop=2
set shiftwidth=2
set autoindent
set hlsearch
set incsearch
syntax on

# YAML file detection and settings
autocmd BufNewFile,BufRead *.yaml,*.yml set filetype=yaml
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab autoindent

# Show whitespace issues
set list
set listchars=tab:>-,trail:-

# Quick command shortcuts
nnoremap <Leader>s :%s/\<<C-r><C-w>\>//g<Left><Left>
```

---

## Conclusion

Mastering vi takes practice, but it's worth the investment. Start with basic navigation and editing, then gradually incorporate more advanced features. Remember:

1. **Practice regularly** - The more you use vi, the more natural it becomes
2. **Start simple** - Master basic commands before moving to advanced features
3. **Use help** - Type `:help` in vi for built-in documentation
4. **Be patient** - Vi has a learning curve, but it's very rewarding

The key to vi mastery is muscle memory. With consistent practice, these commands will become second nature, making you incredibly efficient at text editing.

### Additional Resources
- Vi/Vim online tutorials: `vimtutor` command
- Vi cheat sheets available online
- Practice with real files in your daily work
- Explore vim (vi improved) for additional features

Happy editing! 🚀