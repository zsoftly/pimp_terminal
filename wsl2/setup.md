# Complete End-to-End Guide for Setting Up WSL 2 Instances

## 1. Enable WSL via PowerShell (Prerequisites)

```powershell
# Enable required Windows features
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart your computer after this step

# Set WSL 2 as default
wsl --set-default-version 2
```

## 2. Install Ubuntu 24.04

```powershell
# Install Ubuntu 24.04 from Microsoft Store
wsl --install -d Ubuntu-24.04
```

When prompted during first launch, create your username and password.

## 3. Create Export Directory

```powershell
# Create temp directory for the export
mkdir C:\temp
```

## 4. Export Base Ubuntu

```powershell
# Terminate the instance if it's running
wsl --terminate Ubuntu-24.04

# Export to a tar file
wsl --export Ubuntu-24.04 C:\temp\ubuntu24.tar
```

## 5. Create Custom Instances

```powershell
# Create directories for instances
mkdir C:\WSL\ditah_ps
mkdir C:\WSL\ditah_zs

# Import the instances
wsl --import ditah_ps C:\WSL\ditah_ps C:\temp\ubuntu24.tar
wsl --import ditah_zs C:\WSL\ditah_zs C:\temp\ubuntu24.tar
```

## 6. Configure First Instance (ditah_ps)

```powershell
# Launch the first instance
wsl -d ditah_ps
```

Inside the ditah_ps WSL instance:
```bash
# Set hostname directly (don't use hostnamectl as it won't work in WSL)
echo "personal" | sudo tee /etc/hostname

# Update hosts file
sudo sed -i '/127.0.1.1/d' /etc/hosts
echo "127.0.1.1 personal" | sudo tee -a /etc/hosts

# Create a non-root user (replace yourname with preferred username)
# Skip this if you're already logged in as a non-root user
NEW_USER=yourname # NEW_USER=dk
sudo useradd -m -G sudo -s /bin/bash $NEW_USER
sudo passwd $NEW_USER

# Configure WSL to use this hostname and default user permanently
echo -e "[network]\nhostname = personal\n\n[user]\ndefault = $NEW_USER" | sudo tee /etc/wsl.conf

# Exit this instance
exit
```

## 7. Configure Second Instance (ditah_zs)

```powershell
# Launch the second instance
wsl -d ditah_zs
```

Inside the ditah_zs WSL instance:
```bash
# Set hostname directly (don't use hostnamectl as it won't work in WSL)
echo "zsoftly" | sudo tee /etc/hostname

# Update hosts file
sudo sed -i '/127.0.1.1/d' /etc/hosts
echo "127.0.1.1 zsoftly" | sudo tee -a /etc/hosts

# Create a non-root user (replace yourname with preferred username)
# Skip this if you're already logged in as a non-root user
NEW_USER=yourname #NEW_USER=dkzs
sudo useradd -m -G sudo -s /bin/bash $NEW_USER
sudo passwd $NEW_USER

# Configure WSL to use this hostname and default user permanently
echo -e "[network]\nhostname = zsoftly\n\n[user]\ndefault = $NEW_USER" | sudo tee /etc/wsl.conf

# Exit this instance
exit
```

## 8. Restart Instances to Apply Changes

```powershell
# Shut down all WSL instances to apply the changes
wsl --shutdown

# Wait a few seconds
Start-Sleep -Seconds 5

# Restart the instances with new settings
wsl -d ditah_ps
wsl -d ditah_zs
```

## 9. Verify Hostname Configuration

Inside each WSL instance:
```bash
# Check the current hostname
hostname

# Make sure sudo works without hostname errors
sudo echo "Hostname is working correctly"
```

## 10. Managing Your Instances

```powershell
# List all WSL instances and their status
wsl --list -v

# Start a specific instance
wsl -d ditah_ps

# Terminate a specific instance when done
wsl --terminate ditah_ps

# Shutdown all WSL instances
wsl --shutdown

# Unregister (remove) an instance if no longer needed
# This deletes the virtual disk and all contents of that instance
wsl --unregister ditah_ps
```

## 11. Cleaning Up (Optional)

```powershell
# If you want to save disk space after setting up instances
del C:\temp\ubuntu24.tar
```

## Important Notes

1. **Don't use `hostnamectl`**: As demonstrated, `hostnamectl` doesn't work in WSL because it relies on systemd, which is not fully supported in the default WSL configuration.

2. **Hostname persistence**: The hostname is configured in /etc/wsl.conf which ensures it persists across restarts.

3. **Complete shutdown required**: For hostname changes to take effect, a complete shutdown of all WSL instances is required (not just terminating the specific instance).

4. **Isolation between instances**: Each instance is fully isolated with its own filesystem, processes, and hostname. You can run potentially risky applications in one instance and terminate it when done without affecting your host system or other WSL instances.