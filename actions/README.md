# actions

Mission apprentissage GitHub Actions. Actions designed for project repos.

| Workflow Action                                                          | usage                                                        | 
| ------------------------------------------------------------------------ | ------------------------------------------------------------ | 
| [autodevops-build-register](#socialgouvactionsautodevops-build-register) | Build and register docker images on ghcr.io                  | 
| [autodevops-deploy](#socialgouvactionsautodevops-deploy)                 | Deploy                                                       | 
| [autodevops-release](#socialgouvactionsautodevops-release)               | Trigger semantic release run                                 |


## `mission-apprentissage/infra/actions/autodevops-build-register`

- Build docker image and register it to GHCR

```yaml
- uses: mission-apprentissage/infra/actions/autodevops-build-register@v1
  with:
    project: "my_product"
    imageName: my_product/my_component
    token: ${{ secrets.GITHUB_TOKEN }}
    dockerfile: "/path/to/Dockerfile" # optional
    dockercontext: "/path/to/content" # optional
    dockerbuildargs: | # optional
      NODE_ENV=production
    environment: "preprod" # optional

```

## `mission-apprentissage/infra/actions/autodevops-deploy`

- Deploy application over

```yaml
- uses: mission-apprentissage/infra/actions/autodevops-deploy@v1
  id: deploy
  with:
    environment: "dev"
    token: ${{ secrets.GITHUB_TOKEN }}
```

Export main URL as `steps.deploy.outputs.url`

## `mission-apprentissage/infra/actions/autodevops-release`

- Trigger semantic release run

```yaml
- uses: mission-apprentissage/actions/autodevops-release@v1
  with:
    github-token: ${{ secrets.SOCIALGROOVYBOT_BOTO_PAT }}
```
