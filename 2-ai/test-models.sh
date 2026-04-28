#!/bin/zsh

# List of models to attempt to install via Ollama
# Note: Models marked with :cloud are cloud-based and cannot be pulled locally.
MODELS=(
    "claude-opus-4-6:cloud"                         # Claude Opus 4.6
    "claude-sonnet-4-6:cloud"                      # Claude Sonnet 4.6
    "claude-haiku-4-5:cloud"                       # Claude Haiku 4.5
    "gpt-4o:cloud"                                  # GPT-4o
    "o3:cloud"                                      # o3
    "sonar-pro:cloud"                               # Perplexity Sonar
)

echo "Starting Ollama model installation process..."

for model_entry in "${MODELS[@]}"; do
    # Remove any trailing comments from the string if present in the array
    model_id="${model_entry%% #*}"
    model_id=$(echo "$model_id" | xargs) # trim whitespace

    # if [[ "$model_id" == *":cloud"* ]]; then
    #     echo "Skipping $model_id: Cloud models cannot be installed via Ollama."
    #     continue
    # fi

    echo "Attempting to pull: $model_id..."
    ollama pull "$model_id"

    if [ $? -eq 0 ]; then
        echo "Successfully pulled $model_id"
    else
        echo "Failed to pull $model_id"
    fi
done

echo "Process complete."