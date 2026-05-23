# Switch AWS profile and verify identity
# Usage: switchaws <profile-name>

switchaws() {
  export AWS_PROFILE=$1
  echo "Switched to AWS profile: $AWS_PROFILE"
  aws sts get-caller-identity
}
