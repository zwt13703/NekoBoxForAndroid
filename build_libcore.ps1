# PowerShell script to build libcore.aar on Windows

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = $PSScriptRoot
$PROJECT_ROOT = "$SCRIPT_DIR"
$LIBCORE_DIR = "$PROJECT_ROOT\libcore"
$EXTERNAL_DIR = "$PROJECT_ROOT\external"
$OUTPUT_DIR = "$PROJECT_ROOT\app\libs"

# Ensure output directory exists
if (-not (Test-Path $OUTPUT_DIR)) {
    New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null
}

# 0. Setup ANDROID_HOME from local.properties
$LOCAL_PROPERTIES = "$PROJECT_ROOT\local.properties"
if (Test-Path $LOCAL_PROPERTIES) {
    $content = Get-Content $LOCAL_PROPERTIES
    foreach ($line in $content) {
        if ($line -match "^sdk\.dir=(.*)") {
            $sdk_dir = $matches[1].Trim()
            # Handle escaping: local.properties uses \\ for \ and \: for :
            $sdk_dir = $sdk_dir -replace "\\:", ":"
            $sdk_dir = $sdk_dir -replace "\\\\", "\"
            $env:ANDROID_HOME = $sdk_dir
            Write-Host "Found SDK in local.properties, set ANDROID_HOME to $sdk_dir"
            break
        }
    }
}

# 1. Check Dependencies
Write-Host "Checking dependencies..."
if (-not (Test-Path "$EXTERNAL_DIR\sing-box")) {
    Write-Warning "Missing sing-box source in $EXTERNAL_DIR\sing-box"
    Write-Host "Please clone sing-box: git clone git@github.com:MatsuriDayo/sing-box.git $EXTERNAL_DIR\sing-box"
    git clone git@github.com:MatsuriDayo/sing-box.git "$EXTERNAL_DIR\sing-box"
}
if (-not (Test-Path "$EXTERNAL_DIR\libneko")) {
    Write-Warning "Missing libneko source in $EXTERNAL_DIR\libneko"
    Write-Host "Please clone libneko: git clone git@github.com:MatsuriDayo/libneko.git $EXTERNAL_DIR\libneko"
    git clone git@github.com:MatsuriDayo/libneko.git "$EXTERNAL_DIR\libneko"
}

# 2. Setup Environment
$env:CGO_ENABLED = "1"
# Only set GOOS to android when actually building the library, not for building tools
# $env:GOOS = "android" 
# $env:GOARCH = "arm64" 

# 3. Install gomobile-matsuri
Write-Host "Installing gomobile-matsuri..."
$GOPATH = go env GOPATH
$GOBIN = "$GOPATH\bin"

# Add GOPATH\bin to PATH for the current session
$env:PATH = "$GOBIN;$env:PATH"

try {
    # Check if we have gomobile-matsuri installed
    # Always try to build/install to ensure we have the latest version (especially if we patched the source)
    if ($true) {
        Write-Host "Building gomobile-matsuri..."
        
        $GOMOBILE_REPO = "$EXTERNAL_DIR\gomobile"
        if (-not (Test-Path $GOMOBILE_REPO)) {
             git clone -b master2 git@github.com:MatsuriDayo/gomobile.git $GOMOBILE_REPO
        }
        
        # Build gomobile
        # Ensure we build for HOST OS (Windows), not Android
        $env:GOOS = "windows"
        $env:GOARCH = "amd64"
        
        Push-Location "$GOMOBILE_REPO\cmd\gomobile"
        go install -v
        Pop-Location
        
        # Build gobind
        Push-Location "$GOMOBILE_REPO\cmd\gobind"
        go install -v
        Pop-Location
        
        # Reset Env
        $env:GOOS = $null
        $env:GOARCH = $null
        
        # Rename binaries if needed, or assume they are in GOPATH/bin
        # Windows usually puts them in %GOPATH%\bin
        
        Write-Host "Please manually rename/copy binaries if script fails due to permission:"
        Write-Host "  $GOBIN\gomobile.exe -> $GOBIN\gomobile-matsuri.exe"
        Write-Host "  $GOBIN\gobind.exe -> $GOBIN\gobind-matsuri.exe"

        # Try to copy but ignore error if we can't (user might have done it, or we rely on them doing it)
        try {
            if (Test-Path "$GOBIN\gomobile.exe") {
                Copy-Item "$GOBIN\gomobile.exe" "$GOBIN\gomobile-matsuri.exe" -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path "$GOBIN\gobind.exe") {
                Copy-Item "$GOBIN\gobind.exe" "$GOBIN\gobind-matsuri.exe" -Force -ErrorAction SilentlyContinue
            }
        } catch {
             Write-Warning "Could not copy binaries automatically. Please ensure gomobile-matsuri.exe exists in PATH."
        }
    }
    
    # Check current directory for gomobile-matsuri too, in case user put it there or we can use it from there
    if (Test-Path "$GOBIN\gomobile.exe") {
         # If we can't rename, we can try to use a shim or alias, but for now let's just warn loudly
    }

    # Verify installation
    if (-not (Get-Command "gomobile-matsuri" -ErrorAction SilentlyContinue)) {
        # Fallback: if we built gomobile, but failed to rename, check if we can just use "gomobile" but users wanted "gomobile-matsuri"
        # Since the script relies on "gomobile-matsuri", we must have it.
        
        Write-Warning "gomobile-matsuri not found. Attempting to use local copy in project root if available..."
        # Last ditch effort: copy to temp dir and add to path? No, that's messy.
        
        throw "gomobile-matsuri executable not found in PATH. Please manually copy '$GOBIN\gomobile.exe' to '$GOBIN\gomobile-matsuri.exe' and '$GOBIN\gobind.exe' to '$GOBIN\gobind-matsuri.exe'"
    }
}
catch {
    Write-Error "Failed to install gomobile: $_"
    exit 1
}

# 4. Build libcore.aar
Write-Host "Building libcore.aar..."
Push-Location $LIBCORE_DIR

$env:GOBIND = "gobind-matsuri"
$BUILD_CACHE = "$LIBCORE_DIR\.build"

# Clean previous build
if (Test-Path $BUILD_CACHE) { Remove-Item -Recurse -Force $BUILD_CACHE }

# Run gomobile bind
# Note: We need to specify the Android API level and tags
$TAGS = "with_conntrack,with_gvisor,with_quic,with_wireguard,with_utls,with_clash_api"

# Ensure android platform is available for gomobile
gomobile-matsuri init

Write-Host "Running gomobile bind..."
gomobile-matsuri bind -v -target android -androidapi 21 -ldflags='-s -w' -tags=$TAGS -o "$OUTPUT_DIR\libcore.aar" .

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful! libcore.aar created at $OUTPUT_DIR\libcore.aar"
} else {
    Write-Error "Build failed."
}

Pop-Location
