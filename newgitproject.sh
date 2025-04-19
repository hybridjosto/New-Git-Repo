#!/bin/bash

# Handle Ctrl+C (SIGINT) to exit cleanly
exit_handler() {
  echo -e "\n🚪 Exiting..."
  exit 1
}
trap exit_handler SIGINT

setup_proj() {
  ACCOUNT=$(gum choose --header "Select your GitHub account: " "hybridjosto" "jstockwell-bedford")
  echo "🔄 Switching to $ACCOUNT GitHub account..."
  gh auth switch --hostname github.com --user "$ACCOUNT" || {
    echo "❌ Failed to switch to $ACCOUNT. Make sure you're logged in with \`gh auth login\`."
    exit 1
  }

  # SSH host alias based on account choice
  if [ "$ACCOUNT" = "personal" ]; then
    SSH_HOST_ALIAS="github-personal"
  else
    SSH_HOST_ALIAS="github-work"
  fi
  NAME=$(gum input --prompt "Enter the name of your new project: " --placeholder "my-project")
  # Replace spaces with hyphens for repository naming
  NAME_SLUG="${NAME// /-}"
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

    # Create GitHub repo with hyphenated name
    gh repo create "$NAME_SLUG" --public --description "$DESCRIPTION" "${SOURCE_ARGS[@]}"

    # Add remote origin if not already added
    if ! git remote get-url origin >/dev/null 2>&1; then
      USERNAME=$(gh api user -q .login)
      git remote add origin git@$SSH_HOST_ALIAS:$USERNAME/$NAME_SLUG.git
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
    git push origin main
  else
    echo "❌ Setup cancelled"
  fi
}

setup_proj
