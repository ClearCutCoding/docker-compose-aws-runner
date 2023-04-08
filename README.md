# Docker Compose AWS Runner

- Ensure the `aws` cli is installed and configured
- Ensure `docker-compose` cli is installed
- Create config in same folder as `docker-compose.yaml` named `docker-compose-aws-runner.cfg`


```
aws.account=https://1234.dkr.ecr.eu-west-1.amazonaws.com
aws.profile=xxx-devuser
network=test
```

- Run `./docker-compose-aws-runner.sh`

