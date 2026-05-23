# Copy to ~/.config/ec2-instances.zsh and edit for your own account.

REGION="us-west-2"
DEFAULT_INSTANCE="dev"

typeset -A INSTANCES
INSTANCES=(
  "dev" "i-0123456789abcdef0"
)
