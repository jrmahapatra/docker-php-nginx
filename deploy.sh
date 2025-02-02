# Create a new builder instance with multi-platform support
docker buildx create --name mybuilder --use

# Build and push the multi-platform image
docker buildx build --platform linux/arm64,linux/amd64 -t mjanaki/php82-alpine-nginx:latest . --push