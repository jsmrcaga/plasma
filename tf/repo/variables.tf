variable github_token {
  type = string
  sensitive = true
}

variable github {
  type = object({
    secrets = object({
      docker_username = string
      docker_password = string
    })
  })
}
