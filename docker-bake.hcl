variable "NETDISCO_GIT_URL" {
  default = "https://github.com/netdisco/netdisco.git"
}

variable "COMMITTISH" {
  default = "latest"
}

variable "BUILD_DATE" {
  default = ""
}

group "default" {
  targets = ["netdisco-backend","netdisco-web"]
}

group "standalone" {
  targets = ["netdisco-postgresql","netdisco-backend", "netdisco-web"]
}

group "all" {
  targets = ["netdisco-postgresql","netdisco-postgresql-13","netdisco-backend", "netdisco-web"]
}

target "netdisco-base" {
  context    = "./netdisco-base"
  dockerfile = "Dockerfile"
  tags = [
    "localhost:5000/netdisco:${COMMITTISH}-base",
  ]
  args = {
    COMMITTISH       = COMMITTISH
    NETDISCO_GIT_URL = NETDISCO_GIT_URL
  }
  output = ["type=docker"]
}

target "netdisco-web" {
  context    = "./netdisco-web"
  dockerfile = "Dockerfile"
  tags = [
    "localhost:5000/netdisco:${COMMITTISH}-web",
  ]
  args = {
    COMMITTISH = COMMITTISH
  }
  contexts = {
    "localhost:5000/netdisco:${COMMITTISH}-base" = "target:netdisco-base"
  }
  output = ["type=docker"]
}

target "netdisco-backend" {
  context    = "./netdisco-backend"
  dockerfile = "Dockerfile"
  tags = [
    "localhost:5000/netdisco:${COMMITTISH}-backend",
  ]
  args = {
    COMMITTISH = COMMITTISH
  }
  contexts = {
    "localhost:5000/netdisco:${COMMITTISH}-base" = "target:netdisco-base"
  }
  output = ["type=docker"]
}

target "netdisco-postgresql" {
  context    = "./netdisco-postgresql"
  dockerfile = "Dockerfile"
  tags = [
    "localhost:5000/netdisco:${COMMITTISH}-postgresql",
  ]
  args = {
    COMMITTISH = COMMITTISH
    BUILD_DATE = BUILD_DATE
  }
  output = ["type=docker"]
}

target "netdisco-postgresql-13" {
  context    = "./netdisco-postgresql"
  dockerfile = "Dockerfile"
  tags = [
    "localhost:5000/netdisco:${COMMITTISH}-postgresql-13",
  ]
  args = {
    PGVER      = "13.4"
    COMMITTISH = COMMITTISH
    BUILD_DATE = BUILD_DATE
  }
  output = ["type=docker"]
}
