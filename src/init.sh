# Run pre-hooks
for file in /plasma-pre-hooks.d/*.sh; do
  bash "$file"
done

# Configure screen
# -> Should have happened in Dockerfile

# Configure Sunshine
# -> Mount config from user-land using volumes

# Run post-hooks
for file in /plasma-post-hooks.d/*.sh; do
  bash "$file"
done

# Start x server?

# Start container
steam && sunshine
