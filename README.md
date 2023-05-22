# Docker Compose AWS Runner

- Ensure the `aws` cli is installed and configured
- Ensure `docker-compose` cli is installed
- Create config in same folder as `docker-compose.yaml` named `docker-compose-aws-runner.cfg`


```
aws.account=https://1234
aws.region=eu-west-1
aws.profile=xxx-devuser
network=test
```

- Run `docker-compose-aws-runner` from inside the directory with `docker-compose.yaml`

