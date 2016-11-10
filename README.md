# build-scripts

A centralized repository for Womply build scripts.

Currently used as a canonical repository that our circleCI builds
can reference in order to do common build processes.

Broken down into:
- setup-java-service
   - setup-docker: downloads docker 1.8.2 and logs into quay
   - setup-jce: installs JCE unlimited crypto 
     - this depends on a private s3 bucket due to oracle website instability
   - setup-maven: sets up maven settings.xml and re-versions project
- build-java-service
   - mvn deploy
   - code coverage check (updated to sleep 10s between runs)
      - parse-coveralls.py broken out into a multiline .py script
- cache-java-service: caches docker images
- deploy-java-service
   - calculate current version for use by subscripts
   - do-ecs-deployment: pushes properly tagged docker image to ecs
   - do-release-notes: generates git tag w/ attached release notes
   - do-slack-notification: notifies slack of new builds/deploys
