$ErrorActionPreference = "Stop"

#$env:PACKER_LOG=1
#$env:PACKER_LOG_PATH="packerlog.txt"

function UpdateVaultToken {
    $Body = @{
        role_id = $Env:VAULT_ROLE_ID
        secret_id = $Env:VAULT_SECRET_ID
    }
    $tokenResponse = Invoke-RestMethod -Method 'Post' -SkipCertificateCheck -Uri "$Env:VAULT_ADDR/v1/auth/approle/login" -Body $body
    $Env:VAULT_TOKEN = $tokenResponse.auth.client_token
}

UpdateVaultToken
docker run --rm --privileged `
    -e PACKER_LOG=1 -e PACKER_LOG_PATH=packerlog.txt -e VAULT_ADDR=$Env:VAULT_ADDR -e VAULT_TOKEN=$Env:VAULT_TOKEN -e VAULT_SKIP_VERIFY=$Env:VAULT_SKIP_VERIFY `
    -v /dev:/dev -v ${PWD}:/build `
    mkaczanowski/packer-builder-arm build pidev.pkr.hcl
