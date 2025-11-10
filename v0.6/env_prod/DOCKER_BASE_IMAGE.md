# IMPORTANT: First-Time Setup for Docker Base Images

The test and prod Dockerfiles now use a pre-built base image:
`tsouche/set_backend_testprod:v0.6.0`

## Before First Deployment

You MUST build and push the base image to DockerHub first.

### Quick Setup (Recommended)

From `/workspace/set_backend/images_dev_test_prod/`:

```bash
# Step 1: Login to DockerHub on NAS
./dockerhub_login.sh

# Step 2: Build and push base image
./build_and_push_on_nas.sh testprod
```

### Manual Setup (Alternative)

If the automated script doesn't work:

```bash
# 1. SSH to NAS
ssh -p 5522 thierry@100.100.10.1

# 2. Create temp directory
mkdir -p /tmp/docker_base && cd /tmp/docker_base

# 3. Copy Dockerfile content
# (Copy the content of images_dev_test_prod/Dockerfile.testprod)

# 4. Build image
docker build -f Dockerfile.testprod \
  -t tsouche/set_backend_testprod:v0.6.0 .

# 5. Tag versions
docker tag tsouche/set_backend_testprod:v0.6.0 \
  tsouche/set_backend_testprod:v0.6
docker tag tsouche/set_backend_testprod:v0.6.0 \
  tsouche/set_backend_testprod:latest

# 6. Login to DockerHub
docker login -u tsouche

# 7. Push all tags
docker push tsouche/set_backend_testprod:v0.6.0
docker push tsouche/set_backend_testprod:v0.6
docker push tsouche/set_backend_testprod:latest

# 8. Cleanup
cd ~ && rm -rf /tmp/docker_base
```

## Verification

After pushing, verify the image is available:

```bash
docker pull tsouche/set_backend_testprod:v0.6.0
```

## Benefits

Once the base image is published:

- **Build time**: 180s → 15s (92% faster)
- **Network**: 420MB → 0MB (cached)
- **Consistency**: Same base for test and prod

## When to Update Base Image

Update the base image when:
- SET Backend version changes (update version tag)
- Runtime dependencies change
- MongoDB version updates
- System libraries need updates

Then:
1. Update version in Cargo.toml
2. Rebuild base image: `./build_and_push_on_nas.sh testprod`
3. Update FROM line in Dockerfiles
4. Deploy as usual
