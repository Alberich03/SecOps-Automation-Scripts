# ============================
#  NUCLEI SCANNER - SEPARATE FILES (PowerShell)
# ============================

# ==== KONFIGURASI (boleh ubah) ====
$List   = 'C:\Users\Aubrey\Downloads\5_domain.txt'
$OutDir = 'C:\Users\Aubrey\Downloads'
$Prefix = '24-09-2025_nuclei_'
# ===================================

Write-Host "========================================"
Write-Host "  NUCLEI SCANNER - SEPARATE FILES"
Write-Host "========================================`n"
Write-Host "[CONFIG] Domain list: $List"
Write-Host "[CONFIG] Output directory: $OutDir"
Write-Host "[CONFIG] File prefix: $Prefix`n"

# Cek file list
if (-not (Test-Path -LiteralPath $List)) {
    Write-Error "[ERROR] File list tidak ditemukan: $List"
    Read-Host "Press Enter to exit"
    exit 1
}

# Pastikan folder output ada
if (-not (Test-Path -LiteralPath $OutDir)) {
    try {
        New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
    } catch {
        Write-Error "[ERROR] Gagal membuat folder output: $OutDir"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Cek nuclei ada di PATH
if (-not (Get-Command nuclei -ErrorAction SilentlyContinue)) {
    Write-Error "[ERROR] 'nuclei' tidak ditemukan di PATH. Tambahkan ke PATH atau pakai path penuh ke nuclei.exe"
    Read-Host "Press Enter to exit"
    exit 1
}

# Loop tiap domain
Get-Content -LiteralPath $List | ForEach-Object {
    $domain = $_.Trim()
    if ([string]::IsNullOrWhiteSpace($domain)) { return }

    # Nama file aman: buang protokol & ganti karakter ilegal Windows
    $safe = $domain -replace '^https?://',''
    $safe = $safe -replace '[:/\\|<>?*"]','_'

    $outfile = Join-Path $OutDir ($Prefix + $safe + '.txt')

    Write-Host "[SCAN] $domain"
    try {
        & nuclei -target $domain `
                 -o $outfile `
                 -severity info,low,medium,high,critical `
                 -stats -v
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "[WARN] Nuclei exit code $LASTEXITCODE untuk '$domain' (lanjut domain berikutnya)"
        } else {
            Write-Host "[DONE] $outfile"
        }
    } catch {
        Write-Warning "[WARN] Gagal scan '$domain' : $($_.Exception.Message)"
    }
    Write-Host
}

Write-Host "[OK] Selesai."
Read-Host "Press Enter to exit"
exit 0
