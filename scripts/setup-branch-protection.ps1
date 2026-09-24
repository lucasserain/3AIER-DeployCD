# Aplica branch protection na main via GitHub CLI.
# Pré-requisito: gh instalado e autenticado (gh auth login) com permissão de admin no repo.
# Uso: .\scripts\setup-branch-protection.ps1 [-Repo owner/nome] [-Branch main]

param(
    [string]$Repo = "lucasserain/3AIER-DeployCD",
    [string]$Branch = "main"
)

$body = @'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["checklist"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "require_code_owner_reviews": true,
    "dismiss_stale_reviews": true,
    "require_last_push_approval": true
  },
  "restrictions": null,
  "required_conversation_resolution": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
'@

# PowerShell 5.1 adiciona BOM ao fazer pipe para executáveis; grava UTF-8 sem BOM em arquivo.
$tmp = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmp, $body, (New-Object System.Text.UTF8Encoding $false))
try {
    gh api --method PUT "repos/$Repo/branches/$Branch/protection" `
        -H "Accept: application/vnd.github+json" --input $tmp
    if ($LASTEXITCODE -ne 0) { throw "Falha ao aplicar branch protection" }
} finally {
    Remove-Item $tmp -ErrorAction SilentlyContinue
}

Write-Host "Branch protection aplicada em $Repo@$Branch"
gh api "repos/$Repo/branches/$Branch/protection" --jq '{reviews: .required_pull_request_reviews.required_approving_review_count, code_owners: .required_pull_request_reviews.require_code_owner_reviews, checks: .required_status_checks.contexts, admins: .enforce_admins.enabled}'
