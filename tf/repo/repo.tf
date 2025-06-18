module repo {
  source = "git@github.com:jsmrcaga/terraform-modules//github-repo?ref=v0.2.3"

  github = {
    token = var.github_token
  }

  name = "plasma"
  description = "A lightweight and unbloated Steam headless Docker image"

  topics = ["steam", "sunshine", "gaming", "streaming"]

  has_wiki = true

  actions = {
    secrets = {
      DOCKER_USERNAME = var.github.secrets.docker_username
      DOCKER_PASSWORD = var.github.secrets.docker_password
    }
  }
}
