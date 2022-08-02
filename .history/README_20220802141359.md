# workHORSE app dockerfile

This repo hosts the dockerfile for the deployment of the [workHORSE app](https://github.com/ChristK/workHORSE/).

Every time a change is pushed on this repo a new docker container is built automatically at dockerhub. 

To install and push to dockerhub manually
```bash
sudo docker build --no-cache -t [docker-USERNAME]/workhorse-app . # replace [docker-USERNAME] with your docker usename
sudo docker login
sudo docker push [docker-USERNAME]/workhorse-app . # replace [docker-USERNAME] with your docker usename
```
