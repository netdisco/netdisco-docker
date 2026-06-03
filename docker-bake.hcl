variable "NETDISCO_GIT_URL" {
  default = "https://github.com/netdisco/netdisco.git"
}

variable "COMMITTISH" {
  default = "HEAD"
}

variable "BUILD_DATE" {
  default = ""
}

group "default" {
  targets = ["netdisco"]
}

group "standalone" {
  targets = ["netdisco-postgresql","netdisco"]
}

group "all" {
  targets = ["netdisco-postgresql","netdisco-postgresql-13","netdisco"]
}

target "netdisco-base" {
  context = "./netdisco-base"
  args = {
    COMMITTISH       = COMMITTISH
    NETDISCO_GIT_URL = NETDISCO_GIT_URL
  }
  tags = [
    "localhost:5000/netdisco:${COMMITTISH}-base",
  ]
  output = ["type=docker"]
}

target "netdisco" {
  name = "netdisco-${tgt}"
  matrix = {
    tgt = ["backend", "web"]
  }
  context = "./netdisco-${tgt}"
  args = {
    COMMITTISH = COMMITTISH
    BUILD_DATE = BUILD_DATE
  }
  tags = [
    "localhost:5000/netdisco:${COMMITTISH}-${tgt}",
  ]
  contexts = {
    "localhost:5000/netdisco:${COMMITTISH}-base" = "target:netdisco-base"
  }
  output = ["type=docker"]
}

target "netdisco-postgresql" {
  context = "./netdisco-postgresql"
  args = {
    COMMITTISH = COMMITTISH
    BUILD_DATE = BUILD_DATE
  }
  tags = [
    "localhost:5000/netdisco:${COMMITTISH}-postgresql",
  ]
  output = ["type=docker"]
}

target "netdisco-postgresql-13" {
  context = "./netdisco-postgresql"
  args = {
    PGVER      = "13.4"
    COMMITTISH = COMMITTISH
    BUILD_DATE = BUILD_DATE
  }
  tags = [
    "localhost:5000/netdisco:${COMMITTISH}-postgresql-13",
  ]
  output = ["type=docker"]
}
