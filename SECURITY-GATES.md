## Per-stage security gates


| stage          | tool        | reads                                                                    | fail when                                                                 | warn when                                                                                                             | info when                          | why                                                                                                                                                                                                                             |
| -------------- | ----------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| secrets        | Gitleaks    | Git history, commits, working tree                                       | A suspected secret/credential is detected                                 | —                                                                                                                     | Informational pattern match        | A false positive is cheap to review and allowlist, but a missed real secret can be exposed publicly and cannot be reliably undone; therefore suspected secrets fail.                                                            |
| SCA            | OSV-Scanner | `requirements.txt`, lockfiles/dependency manifests                       | A dependency has a known high/critical vulnerability with a fix available | A lower-severity vulnerability, or a high/critical vulnerability with no fix that is covered by an approved allowlist | Dependency/version inventory       | A fixable high/critical vulnerability is actionable and should block; no-fix findings need an owner and expiry through the allowlist rather than being ignored indefinitely.                                                    |
| SAST           | Semgrep     | Application source code                                                  | A high-confidence security finding is detected                            | A lower-confidence finding is detected                                                                                | Informational/code-quality finding | SAST guesses from code without running the app, so it produces false positives; only high-confidence findings fail, while the rest warn.                                                                                        |
| IaC            | Checkov     | Terraform, Dockerfiles, GitHub Actions/workflows and other configuration | A high/critical security misconfiguration is detected                     | A lower-severity or non-security-critical policy violation is detected                                                | Informational policy result        | IaC findings are true configuration facts, but not every policy violation has the same blast radius for the application; security-critical misconfigurations fail, while lower-impact ones warn.                                |
| container scan | Trivy       | Built container image, OS packages and application dependencies          | A high/critical vulnerability with a fix available is found in the image  | A lower-severity vulnerability, or a high/critical vulnerability with no fix that is covered by an approved allowlist | Image/package inventory            | The image is the artifact that ships, so a fixable high/critical vulnerability directly affects what reaches production; no-fix findings need an owner and expiry through the allowlist rather than being ignored indefinitely. |
| DAST           | OWASP ZAP   | Running application over HTTP(S)                                         | A confirmed high-impact vulnerability is detected **in staging**          | A lower-confidence or lower-impact finding is detected                                                                | Informational observation          | DAST runs against the deployed application after merge, so it cannot block the PR; a red result blocks promotion/release instead, while lower-impact findings warn.                                                             |


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
