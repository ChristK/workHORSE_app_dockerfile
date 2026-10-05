# workHORSE app (latest) dockerfile

This repo hosts the dockerfile for the deployment of the [workHORSE app](https://github.com/ChristK/workHORSE/).

The image builds on `chriskypri/workhorse-r-prerequisite` (R 4.2.1 with package versions frozen on 01/08/2022, see the [prerequisite repo](https://github.com/ChristK/workHORSE_prerequisite_dockerfile)), pinned by digest. It installs a chosen commit of the workHORSE repository (default: master) and downloads the large data files from the workHORSE GitHub release. The build stops if any data file is missing or corrupt, or if the workHORSE commit is older than these checks (before 2026-10-05).

Nothing is built automatically: pushing to this repo does not trigger a build on Docker Hub.

## Updating the image and the live app

Run these on the host that serves the app (currently dh012142.liv.ac.uk), from this folder. You need to be in the `docker` group (no `sudo`) and logged in to Docker Hub (`docker login -u chriskypri`).

```bash
# 1. Build. Pinning the commit records it in the image and makes Docker
#    rebuild from the clone step when master has moved.
SHA=$(git ls-remote https://github.com/ChristK/workHORSE.git refs/heads/master | cut -f1)
TAG=$(date +%F)
docker build --pull --build-arg WORKHORSE_SHA=$SHA -t chriskypri/workhorse-app:$TAG .

# 2. Test on a local-only port before publishing.
docker run -d --name workhorse-test -p 127.0.0.1:9900:9898 chriskypri/workhorse-app:$TAG
curl -s -o /dev/null -w '%{http_code}\n' --retry 30 --retry-delay 2 --retry-all-errors http://127.0.0.1:9900/   # 200
docker exec workhorse-test git -C /root/workHORSE log -1 --oneline
docker exec workhorse-test Rscript /root/workHORSE/gh_deploy.R /root/workHORSE   # All 46 data files are present and intact.
#    Open http://localhost:9900 (e.g. through an ssh tunnel) and run a small
#    simulation. When you have finished testing:
docker rm -f workhorse-test

# 3. Publish the dated tag and latest. Dated tags stay on Docker Hub, so any
#    published version can be pulled again for a rollback.
docker tag chriskypri/workhorse-app:$TAG chriskypri/workhorse-app:latest
docker push chriskypri/workhorse-app:$TAG
docker push chriskypri/workhorse-app:latest

# 4. Replace the live container on port 9899. A container keeps the image it
#    was created from, so pushing alone does not change the live app.
#    Rename first: if an old workhorse-app-prev is still there, the rename fails
#    and the live app keeps running. Remove that old one first, unless you
#    still need it for a rollback: docker rm workhorse-app-prev
docker rename workhorse-app workhorse-app-prev && docker stop workhorse-app-prev
docker run -d --name workhorse-app --restart unless-stopped -p 9899:9898 \
  -v /mnt/storage_fast/synthpop/workhorse:/mnt/storage_fast/synthpop \
  chriskypri/workhorse-app:latest
curl -s -o /dev/null -w '%{http_code}\n' --retry 30 --retry-delay 2 --retry-all-errors http://localhost:9899/   # 200

# Roll back if needed:
#   docker rm -f workhorse-app && docker rename workhorse-app-prev workhorse-app && docker start workhorse-app
# Once the new version works:
#   docker rm workhorse-app-prev
```

## Notes

- Mount the synthpop cache from `/mnt/storage_fast/synthpop/workhorse`, not from `/mnt/storage_fast/synthpop` itself. The app's "delete all synthpops" button deletes every file under the mounted folder, and that folder holds other projects' data.
- After an update, the first simulation for each area is slower, because the app regenerates that area's synthetic population.
- `gh_deploy.R` downloads about 1.8 GB from the workHORSE GitHub release and checks every file against `gh_deploy_files.csv`.
- Rebuild the prerequisite image only when R or package versions must change. Then put its new digest in this Dockerfile's `FROM` line.
- Do not point health checks or uptime monitors with a short timeout at the app. Each page load takes about 2.5 s of R time, and requests that time out pile up.
- The `stable` (May 2021) and `HF-REAL` (July 2021) tags were built from the same-named branches of this repo and of workHORSE. This process does not update them.
