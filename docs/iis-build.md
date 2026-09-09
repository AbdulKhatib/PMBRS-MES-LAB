# PMBRS — Server & IIS Build (Stage 2)

## Summary

Windows Server 2022 (pmbrs-app-vm) was configured with IIS, then bridged to a Python/Flask application via wfastcgi — since IIS does not natively execute Python. This document covers the server/IIS build and the application bridge together, as the two incidents encountered span both.

## Server

- Windows Server 2022, t3.micro, us-east-2b
- Same VPC/subnet as the DB tier (see `architecture.md`)
- IIS role installed via Server Manager (Web Server (IIS) role, including Management Tools and CGI feature). FTP Server components were also installed as part of the default role selection — not used in this build, left in place rather than removed, and noted here so it's not mistaken for an unexplained addition.

## Verification — Default Site

The default IIS welcome page was confirmed reachable from an external browser (not just the RDP session) at the instance's public IP, proving the full path: internet → security group → Windows Firewall → IIS → response.

## Python / Flask Bridge

IIS serves static content and .NET applications natively; it has no built-in mechanism to run Python. The bridge was built as follows:

1. Enabled the CGI feature within the IIS role (`Install-WindowsFeature -Name Web-CGI`)
2. Installed Python 3.14 on the instance
3. Installed Flask and wfastcgi via pip
4. Registered the FastCGI handler with `wfastcgi-enable`, which writes the handler mapping into IIS's `applicationHost.config`
5. Created a dedicated IIS site (`PMBRS`, bound to port 8080, physical path `C:\inetpub\wwwroot\pmbrs`) with its own Application Pool set to "No Managed Code" (the app is not a .NET application)
6. Configured `web.config` in the application folder to route requests through the FastCGI handler to the Flask WSGI application

Full `web.config` and `app.py` are in `/application/`.

## Incidents

### 1. HTTP 500.19 — configuration section locked

**Observed:** First test request to the PMBRS site returned HTTP 500.19, "This configuration section cannot be used at this path."

**Root cause:** IIS locks certain configuration sections — including `<handlers>` — at the server level by default. A site-level `web.config` cannot override a locked section unless it is explicitly unlocked first. This is standard IIS behavior, not a mistake in the site's configuration.

**Resolution:**
```
%windir%\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/handlers
```

### 2. HTTP 500.0 — FastCGI process failed to start (0x8007010b)

**Observed:** After resolving the config lock, the site returned a generic "unknown FastCGI error" (error code 0x8007010b) when attempting to actually invoke Python.

**Root cause:** Python was installed to a per-user location (`C:\Users\Administrator\AppData\Local\Programs\Python\Python314\`). IIS application pools run under a low-privilege virtual identity (`IIS APPPOOL\<sitename>`), which by default cannot read into another user's AppData folder tree. The FastCGI module found and attempted to launch python.exe, but the app pool identity lacked filesystem permission to reach it.

**Resolution:** Granted the specific application pool identity (`IIS APPPOOL\PMBRS`) explicit Read & Execute permission on the Python installation directory, via Windows Security properties on that folder. This resolved the issue without requiring a Python reinstall.

**Note for future deployments:** installing Python "for all users" (which places it under `C:\Program Files\` instead of a per-user AppData path) would avoid this class of issue entirely, and is the more standard approach for a service-run application. The per-user install was not deliberately chosen here — it was the installer's default — and this incident is the direct consequence of that default going unquestioned at install time.

## Application Verification

Once both incidents were resolved, the Flask stub application was confirmed reachable and functional at `http://<public-ip>:8080`, returning the expected response body. This proved the complete bridge — IIS → CGI → FastCGI → wfastcgi → Python → Flask — before any database integration was added (see `database-build.md` and the application's actual routes in `/application/app.py` for the database-connected version).
