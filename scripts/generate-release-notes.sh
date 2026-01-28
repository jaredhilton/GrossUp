#!/bin/bash
# Generate release notes from commits using AI
# Requires: OPENAI_API_KEY or ANTHROPIC_API_KEY environment variable

set -e

# Get commits since last tag
get_commits_since_last_tag() {
    local current_tag=$1
    local previous_tag=$(git describe --tags --abbrev=0 "$current_tag^" 2>/dev/null || echo "")
    
    if [ -z "$previous_tag" ]; then
        # No previous tag, get all commits
        git log --oneline "$current_tag"
    else
        git log --oneline "$previous_tag..$current_tag"
    fi
}

# Generate release notes using OpenAI
generate_with_openai() {
    local commits=$1
    local version=$2
    
    curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{
            \"model\": \"gpt-4o\",
            \"messages\": [
                {
                    \"role\": \"system\",
                    \"content\": \"You are a technical writer creating App Store release notes. Write concise, user-friendly release notes (max 4000 chars) that highlight new features, improvements, and bug fixes. Focus on what users will notice, not technical implementation details. Use bullet points. Don't mention version numbers or dates.\"
                },
                {
                    \"role\": \"user\",
                    \"content\": \"Generate App Store release notes for version $version based on these commits:\\n\\n$commits\"
                }
            ],
            \"max_tokens\": 500
        }" | jq -r '.choices[0].message.content'
}

# Generate release notes using Anthropic Claude
generate_with_anthropic() {
    local commits=$1
    local version=$2
    
    curl -s https://api.anthropic.com/v1/messages \
        -H "Content-Type: application/json" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "{
            \"model\": \"claude-sonnet-4-20250514\",
            \"max_tokens\": 500,
            \"messages\": [
                {
                    \"role\": \"user\",
                    \"content\": \"You are a technical writer creating App Store release notes. Write concise, user-friendly release notes (max 4000 chars) that highlight new features, improvements, and bug fixes. Focus on what users will notice, not technical implementation details. Use bullet points. Don't mention version numbers or dates.\\n\\nGenerate App Store release notes for version $version based on these commits:\\n\\n$commits\"
                }
            ]
        }" | jq -r '.content[0].text'
}

# Main
VERSION=${1:-$(git describe --tags --abbrev=0)}
echo "Generating release notes for $VERSION..."

COMMITS=$(get_commits_since_last_tag "$VERSION")
echo "Commits since last release:"
echo "$COMMITS"
echo ""

if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "Using Anthropic Claude..."
    NOTES=$(generate_with_anthropic "$COMMITS" "$VERSION")
elif [ -n "$OPENAI_API_KEY" ]; then
    echo "Using OpenAI..."
    NOTES=$(generate_with_openai "$COMMITS" "$VERSION")
else
    echo "Error: Set ANTHROPIC_API_KEY or OPENAI_API_KEY"
    exit 1
fi

echo "Generated Release Notes:"
echo "========================"
echo "$NOTES"
echo ""

# Save to file for use in submission
echo "$NOTES" > /tmp/release_notes.txt
echo "Saved to /tmp/release_notes.txt"
