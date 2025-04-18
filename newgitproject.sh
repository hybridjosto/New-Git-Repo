#!/bin/bash

setup_proj() {
  NAME=$(gum input --prompt "Enter the name of your new project: " --placeholder "my-project")
  LANGUAGE=$(gum choose --header "Select the programming language: " "Python" "Bash" "Go")
  DESCRIPTION=$(gum write --placeholder "project description")

  echo "Project: $NAME"
  echo "Language: $LANGUAGE"
  echo "Description: $DESCRIPTION"

  # Set up git source flag conditionally
  SOURCE_ARGS=()
  if gum confirm "Push project files with repo?"; then
    SOURCE_ARGS=(--source=. --push)
  fi

  if gum confirm "Go ahead and create the GitHub repo?"; then
    # Initialise git if it hasn't been
    if [ ! -d ".git" ]; then
      git init
      git branch -M main
      git add .
      git commit -m "Initial commit"
    fi

    gh repo create "$NAME" --public --description "$DESCRIPTION" "${SOURCE_ARGS[@]}"

    # Add remote origin if not already added
    if ! git remote | grep -q '^origin$'; then
      git remote add origin "https://github.com/$(gh api user -q .login)/$NAME.git"
    fi

    # Download .gitignore safely
    GITIGNORE_URL="https://raw.githubusercontent.com/github/gitignore/main/${LANGUAGE}.gitignore"
    if curl -f -o .gitignore "$GITIGNORE_URL"; then
      echo "✅ Downloaded .gitignore for $LANGUAGE"
      git add .gitignore
      git commit -m "Add .gitignore"
      git push origin main
    else
      echo "⚠️ Warning: .gitignore not found for $LANGUAGE"
    fi
  else
    echo "❌ Setup cancelled"
  fi
}

setup_proj
