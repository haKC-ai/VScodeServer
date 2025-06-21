
```
                 ██████████                                                              
                █▓       ░██                                                             
                █▒        ██                                                  
    █████████████░        █████████████████ ████████████ ████████████      ████████████  
   ██         ███░        ███▓▒▒▒▒▒▒▒▒▒▒▒██ █▒▒▒▒▒▒▒▒▓████        █████████▓          ▒█  
   ██         ███         ███▒▒▒▒▒▒▒▒▒▒▒▒▓██████████████▓        ███▓▒      ▒▓░       ▒█  
   ██         ███        ░██▓▒▒▒▒▒▒▒▒▒▒▒▒▒▓██▓▒▒▒▒▒▒▒▒█▓        ███░       ░██░       ▒█  
   ██         ███        ▒██▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒██▓▒▒▒▒▒▒▒▓▒        ██  ▓        ██░       ▓█  
   ██         ██▓        ███▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█▓▒▒▒▒▒▒▒▓▒       ██   █        ██░       ▓  
   ██         ██▒        ██▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▓▒      ██    █        ▓█████████  
   ██                    ██▒▒▒▒▒▒▒▒█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒   ▒███████ █░       ░▓        █  
   ██         ░░         ██▒▒▒▒▒▒▒▒██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█ ▓        ░█ ▓       ░▒       ░█  
   ██         ██░       ░█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█ █░        ▒ █                ░█ 
   ██         ██        ▓█▒▒▒▒▒▒▒▒▒██▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█ █░        ▒ █░               ▒█  
    ██████████  ███████████▓██▓▓█▓█  █▓▒▒▒▒▒▒▒▒▒▓██▓██   █▓▓▓▓▓▓▓█    █▓▓▓▓▓▓▓▓▓▓▓▓▓▓██ 
  .:/====================█▓██▓██=========████▓█▓█ ███======> [ P R E S E N T S ] ====\:.
        /\                 ██▓██           █▓▓▓██ ██                                    
 _ __  /  \__________________█▓█_____________██▓██______________________________ _  _    _ 
_ __ \/ /\____________________██_____________ ███________ _________ __ _______ _  
    \  /         T H E   P I N A C L E    O F   H A K C I N G   Q U A L I T Y  
     \/             
            Name :                            haKC.ai Secure Dev Server V1.0
            Collective:                       haKC.ai
            System:                           UNIX / Linux / MacOS / WinD0$3
            Size:                             1 Script + 1 Disk Worth of Cool
            Supplied by:                      corykennedy     
            Release date:                     Jun 2025 or 1994   

      GROUP NEWS: haKC.ai is Still Looking For haKC Coders & Vibe Artists, 
                  Drop corykennedy A Message on Any Fine BBS in the USA
                        Or On The Internet at cory@haKC.ai.                  
                                                                          /\        
       _ __ ___________________________________________________________  /  \__ _ _ 
       __ __ __ ______________________________________________________ \/ /\____ ___
         |  Notes from the author:                                    \  /         |
         |                                                             \/          |
         |  This single script sets up a fully‑secure, phone‑accessible            |            
         |  VS Code server with baked‑in audit, TLS, TOTP GitHub login,            |   
         |  brute‑force protection, auto‑renewing certs, and a dev‑ready shell.    |
         |  While you sit back and edit your .nanorc                               |
         |                                       Greetz to the real ones. cory     |
         |*~'`^`'~*-,._.,-*~'`^`'~*-,._.,-*~'`^`'~*-,._.,-*~'`^`'~*-,._.,-*~'`^`'~*|

         |*~'`^`'~*-,._.,-*~'`^`'~*-,._.,-*~'`^`'~*-,._.,-*~'`^`'~*-,._.,-*~'`^`'~*|
         |                                                                         |
         |  Features Included:                                                     |
         |                                                                         |
         |  [*] Choose Nginx or Traefik reverse proxy with HTTPS + HTTP/2           |
         |  [*] GitHub OAuth with optional org or team restriction                 |
         |  [*] Enforced TOTP if enabled on GitHub user account                    |
         |  [*] VS Code server listening on an uncommon high port (48722)          |
         |  [*] Password hashed and environment variables stored securely in       |
         |    an immutable `.env` file with salted/sealed contents                  |
         |  [*] Automatic TLS via Certbot + systemd timer‑based renewal            |
         |  [*] Fail2Ban guards proxy endpoint with auto ban on brute‑force        |
         |  [*] Log rotation (daily, compressed, 7× retention)                     |
         |  [*] Placeholder banner page before OAuth flow                           |
         |  [*] Colorful ASCII installer banner + ANSI prompts                     |
         |  [*] POSH devshell with Zsh, Oh My Zsh, Powerlevel10k, Nerd‑style       |
         |    prompts, plugins, and login banner via Figlet + Lolcat               |                                                              
         |                                                                         |
         |*~'`^`'~*-,._.,-*~'`^`'~*-,._.,-*~'`^`'~*-,._.,-*~'`^`'~*-,._.,-*~'`^`'~*|
 
                    Usage Flow:                                                    
                     1. Run the installer                                    
                     2. Enter domain + GitHub OAuth credentials                      
                     3. Select proxy type (Nginx or Traefik)                         
                     4. Upon completion:                                             
                        → Visit https://<domain> on phone or desktop                 
                        → GitHub login + TOTP challenge                             
                        → Access code‑server securely over TLS                      
                     5. SSH into droplet for enriched devshell                      
                        → Colorful prompt, plugins, and splash banner on login                                                            

         |*~'`^`'~*-,._.,-*~'`^`'~*-,._.,-*~'`^`'~*-,._.,-*~'`^`'~*-,._.,-*~'`^`'~*|
         |                                      Greetz to:[*]SHINOBI,DEATH PIRATES | 
         |     __|  _ \  __|  __| __ __| __  /      LEGACY CoWTownComputerCongress |
         |    (_ |    /  _|   _|     |      /                                SecKC |
         |   \___| _|_\ ___| ___|   _|   ____|  Shoutz to: [*] 14.4k Modem Jammers |
         |                                                                         |
 .:/=============================================[ bYњC O R Y H A K Cњ(C)1994!њ ] ====\:.
```
