## Per-stage security gates

| stage          | tool        | reads                                                                    | fail when                                                                                                         | warn when                                                      | info when                          | why                                                                      |
| -------------- | ----------- | ------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- | ---------------------------------- | ------------------------------------------------------------------------ |
| secrets        | Gitleaks    | Git history, commits, working tree                                       | Verified secret/credential is detected                                                                            | Suspected secret requiring review                              | Informational pattern match        | Prevent credentials from entering or remaining in source control         |
| SCA            | OSV-Scanner | `requirements.txt`, lockfiles/dependency manifests                       | Known vulnerability is above the configured severity threshold, or has an available fix for a critical/high issue | Vulnerability below the blocking threshold or no fix available | Dependency/version inventory       | Catch vulnerable third-party dependencies before release                 |
| SAST           | Semgrep     | Application source code                                                  | High-confidence exploitable security finding, such as SQL injection or unsafe XSS                                 | Lower-confidence or lower-severity finding                     | Informational/code-quality finding | Catch insecure application code before runtime                           |
| IaC            | Checkov     | Terraform, Dockerfiles, GitHub Actions/workflows and other configuration | High/critical policy violation or explicitly blocked security misconfiguration                                    | Lower-severity policy violation                                | Informational policy result        | Prevent insecure infrastructure and CI configuration from being deployed |
| container scan | Trivy       | Built container image, OS packages and application dependencies          | Critical/high exploitable vulnerability or prohibited configuration                                               | Lower-severity vulnerability or no-fix finding                 | Image/package inventory            | Catch vulnerabilities in the artifact actually being shipped             |
| DAST           | OWASP ZAP   | Running application over HTTP(S)                                         | Confirmed exploitable high-impact runtime vulnerability                                                           | Lower-confidence or lower-severity finding                     | Informational observation          | Verify security controls against the deployed application                |

## Rollout

Security gates are introduced progressively rather than making every existing finding block the pipeline immediately.

1. **Baseline:** run all scanners and publish their results without blocking.
2. **Block new critical/high findings:** findings introduced by a change block the PR once the scanner is trusted and tuned.
3. **Expand coverage:** progressively enable blocking for SCA, SAST, IaC, container scanning and DAST according to the risk of each stage.
4. **Existing findings:** do not block unrelated legacy findings; track them separately and reduce the baseline over time.
5. **KEV override:** a vulnerability listed in CISA's Known Exploited Vulnerabilities (KEV) catalog is treated as blocking regardless of the normal severity threshold, unless an explicit security-approved exception exists.

## Allowlist format

Allowlist entries must identify the exact finding, its location, reason, owner and expiry/review date. Example from `PLANTED.md`:

```yaml
- id: <scanner-finding-id>
  location: ".github/workflows/flake8.yml:18-23"
  reason: "GitHub Actions are not pinned to immutable commit SHAs"
  owner: "<team-or-owner>"
  expires: "<YYYY-MM-DD>"
```

The allowlist should be version-controlled and changes must go through a PR review.

## Unblock path

* **Fix:** preferred path — remediate the finding and rerun the affected gate.
* **Allowlist PR:** if the finding is accepted risk or a false positive, submit a reviewed, time-bounded allowlist entry with justification and ownership.
* **Break-glass:** for an urgent production/release need, an authorised maintainer may temporarily bypass the gate; the bypass must be recorded, justified and followed by remediation or an allowlist PR.
