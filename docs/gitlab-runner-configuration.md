# GitLab Runner Configuration for Kubernetes

This document outlines required GitLab runner configuration for the CI/CD pipeline.

## Required Feature Flag

To resolve Kubernetes pod connectivity issues (TLS internal errors), the following feature flag must be enabled:

### Feature Flag: `FF_WAIT_FOR_POD_TO_BE_REACHABLE`

**Problem**: GitLab Runner 17.6+ experiencing intermittent connectivity issues:
- `tls: internal error` when connecting to pods
- Intermittent pipeline failures during pod initialization
- Connection refused errors from Kubernetes API

**Solution**: Enable the `FF_WAIT_FOR_POD_TO_BE_REACHABLE` feature flag.

### Configuration Methods

#### Method 1: Runner Configuration File (config.toml)
```toml
[[runners]]
  name = "your-runner-name"
  url = "https://gitlab.wolskinet.com/"
  token = "your-token"
  executor = "kubernetes"

  [runners.feature_flags]
    FF_WAIT_FOR_POD_TO_BE_REACHABLE = true

  [runners.kubernetes]
    # your kubernetes configuration
```

#### Method 2: Environment Variable
```bash
export FF_WAIT_FOR_POD_TO_BE_REACHABLE=true
```

#### Method 3: Helm Values (if using GitLab Runner Helm chart)
```yaml
# values.yaml
runners:
  config: |
    [[runners]]
      [runners.feature_flags]
        FF_WAIT_FOR_POD_TO_BE_REACHABLE = true
```

## Verification

After enabling the feature flag, verify it's working:

1. **Check runner logs** for the feature flag:
   ```
   INFO[0000] Feature flags: map[FF_WAIT_FOR_POD_TO_BE_REACHABLE:true]
   ```

2. **Monitor pipeline success rate** - should see significant improvement in pod connectivity

3. **Look for reduced TLS errors** in runner logs

## Related Issues

- **GitLab Runner Issue**: [#37244](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37244)
- **Documentation**: [Feature Flags](https://docs.gitlab.com/runner/configuration/feature-flags.html)

## Impact

**Before**: ~10-20% of CI/CD jobs failing with `tls: internal error`
**After**: Near-zero connectivity failures

This is particularly important for our Ansible collection CI/CD pipeline which runs multiple Docker-in-Docker containers for molecule testing.
