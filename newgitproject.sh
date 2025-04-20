#!/bin/bash

# Starting new GitHub project setup script with helpful output
echo "🚀 Starting new GitHub project setup..."
# Handle Ctrl+C (SIGINT) to exit cleanly
exit_handler() {
  echo -e "\n🚪 Exiting..."
  exit 1
}
# Trap SIGINT (Ctrl+C) to call exit_handler
trap exit_handler SIGINT

# Main function to set up a new project

setup_proj() {
  # Prompt user to select a GitHub account
  ACCOUNT=$(gum choose --header "Select your GitHub account: " "hybridjosto" "jstockwell-bedford")
  echo "🔄 Switching to $ACCOUNT GitHub account..."
  gh auth switch --hostname github.com --user "$ACCOUNT" || {
    echo "❌ Failed to switch to $ACCOUNT. Make sure you're logged in with \`gh auth login\`."
    exit 1
  }
  echo "✅ Auth switched to $ACCOUNT"

  # SSH host alias based on account choice
  if [ "$ACCOUNT" = "personal" ]; then
    SSH_HOST_ALIAS="github-personal"
  else
    SSH_HOST_ALIAS="github-work"
  fi
  echo "🔑 SSH host alias set to: $SSH_HOST_ALIAS"
  NAME=$(gum input --prompt "Enter the name of your new project: " --placeholder "my-project")
  # Replace spaces with hyphens for repository naming
  # Generate URL-friendly slug by replacing spaces with hyphens
  NAME_SLUG="${NAME// /-}"
  echo "⚙️  Project slug generated: $NAME_SLUG"
  LANGUAGE=$(gum choose --header "Select the programming language: " "Python" "Bash" "Go")
  echo "💻 Selected programming language: $LANGUAGE"
  DESCRIPTION=$(gum write --placeholder "project description")
  echo "📝 Project description set."

  echo "Project: $NAME"
  echo "Language: $LANGUAGE"
  echo "Description: $DESCRIPTION"

  # Set up git source flag conditionally
  SOURCE_ARGS=()
  if gum confirm "Push project files with repo?"; then
    SOURCE_ARGS=(--source=. --push)
  fi
  echo "📦 Source args: ${SOURCE_ARGS[*]:-none}"

  if gum confirm "Go ahead and create the GitHub repo?"; then
    echo "🚧 Creating GitHub repository..."
    # Initialise git if it hasn't been
    if [ ! -d ".git" ]; then
      echo "📂 Initializing local git repository..."
      git init
      git branch -M main
      git add .
      git commit -m "Initial commit"
      echo "✅ Local git repository initialized."
    fi

    # Create GitHub repo with hyphenated name
    echo "🌐 Running: gh repo create $NAME_SLUG --public --description \"$DESCRIPTION\" ${SOURCE_ARGS[*]}"
    gh repo create "$NAME_SLUG" --public --description "$DESCRIPTION" "${SOURCE_ARGS[@]}"
    echo "✅ GitHub repository created: $NAME_SLUG"

    # Add remote origin if not already added
    if ! git remote get-url origin >/dev/null 2>&1; then
      USERNAME=$(gh api user -q .login)
      echo "🔗 Adding remote origin: git@$SSH_HOST_ALIAS:$USERNAME/$NAME_SLUG.git"
      git remote add origin git@"$SSH_HOST_ALIAS":"$USERNAME"/"$NAME_SLUG".git
      echo "✅ Remote origin added."
    fi

    # Download .gitignore safely
    GITIGNORE_URL="https://raw.githubusercontent.com/github/gitignore/main/${LANGUAGE}.gitignore"
    echo "📥 Downloading .gitignore for $LANGUAGE from $GITIGNORE_URL"
    if curl -f -o .gitignore "$GITIGNORE_URL"; then
      echo "✅ Downloaded .gitignore for $LANGUAGE"
      git add .gitignore
      git commit -m "Add .gitignore"
      if git config --global push.autoSetupRemote; then
        git push origin main
      else
        git push --set-upstream origin main
      fi
    else
      echo "⚠️ Warning: .gitignore not found for $LANGUAGE"
    fi
    echo "☁️ Pushing main branch to remote..."
    git push origin main
    echo "🎉 All done! Your project \"$NAME_SLUG\" is live at https://github.com/$ACCOUNT/$NAME_SLUG"
  else
    echo "❌ Setup cancelled"
  fi
}

setup_proj
