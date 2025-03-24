# Remove the old image if it exists (ignore errors if it doesn't)
docker image rm mjanaki/php83-alpine-nginx:latest 2>/dev/null || true

# Create a new builder instance or use existing one
docker buildx create --name mybuilder --use --append || docker buildx use mybuilder

# Build and push the multi-platform image
docker buildx build --platform linux/arm64,linux/amd64 \
    --build-arg TARGETARCH \
    -t mjanaki/php83-alpine-nginx:latest . \
    --push


# docker buildx build --platform linux/arm64 \
#     --build-arg TARGETARCH \
#     -t mjanaki/php83-alpine-nginx:latest . \
#     --push    