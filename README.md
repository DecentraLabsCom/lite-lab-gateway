# 🚀 DecentraLabs Gateway

A The automated setup scripts provide:

- **🔍 Prerequisites check**: Verifies Docker and Docker Compose installation
- **🔐 Smart password management**: Auto-generates secure passwords or lets you set custom ones
- **🌐 Intelligent domain configuration**: Automatically configures for localhost (dev) or production
- **📜 SSL certificate handling**: Generates self-signed certs for localhost, guides for production
- **🚀 One-command deployment**: Starts all services automatically after configuration
- **⚠️ Safe overwrite protection**: Asks before overwriting existing `.env` filesized remote laboratory access gateway with JWT authentication using OpenResty, Guacamole, and MySQL.

## ⚡ Quick Start

### Automated Setup (Recommended)

The setup scripts will automatically:
- ✅ Check Docker prerequisites
- ✅ Configure environment variables
- ✅ Set up database passwords (auto-generated or custom)
- ✅ Configure domain and ports (localhost vs production)
- ✅ Generate SSL certificates for localhost (if needed)
- ✅ Start all services automatically

**Linux/macOS:**
```bash
chmod +x setup.sh
./setup.sh
```

**Windows:**
```cmd
setup.bat
```

That's it! The script will guide you through the setup and start the services automatically.

#### 🎯 Setup Script Features

The automated setup scripts provide:

- **🔍 Prerequisites check**: Verifies Docker and Docker Compose installation
- **🔐 Smart password management**: Auto-generates secure passwords or lets you set custom ones
- **🌐 Intelligent domain configuration**: Automatically configures for localhost (dev) or production
- **� Flexible port selection**: Choose between standard (443/80) or custom ports
- **�📜 SSL certificate handling**: Generates self-signed certs for localhost, guides for production
- **🚀 One-command deployment**: Starts all services automatically after configuration
- **⚠️ Safe overwrite protection**: Asks before overwriting existing `.env` files

### Manual Setup (Advanced Users)

If you prefer manual configuration:

1. **Copy environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` file** with your configuration:
   ```env
   SERVER_NAME=yourdomain.com          # Your domain
   HTTPS_PORT=443                      # 443 for production, 8443 for dev
   HTTP_PORT=80                        # 80 for production, 8080 for dev
   MYSQL_ROOT_PASSWORD=secure_password # MySQL root password
   MYSQL_PASSWORD=guac_db_password     # Guacamole database password
   ```

3. **Add SSL certificates** to `certs/` folder:
   ```
   certs/
   ├── fullchain.pem     # SSL certificate
   ├── privkey.pem       # SSL private key
   └── public_key.pem    # JWT public key
   ```

4. **Start the services:**
   ```bash
   docker-compose up -d
   ```

## 🔐 SSL Certificates

The setup scripts handle SSL certificates automatically:

### For Development (localhost)
- **Automatic**: The setup script generates self-signed certificates
- **Manual**: Place your own certificates in the `certs/` folder

### For Production
You need valid SSL certificates. The setup script will guide you, but you need to obtain them from:

- **Let's Encrypt** (free):
  ```bash
  certbot certonly --standalone -d yourdomain.com
  cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem certs/
  cp /etc/letsencrypt/live/yourdomain.com/privkey.pem certs/
  ```

- **Cloud Providers**: AWS ACM, Cloudflare, etc.
- **Commercial CA**: DigiCert, GlobalSign, etc.

### JWT Public Key
The setup script automatically generates RSA key pair for JWT validation.

For manual setup:
```bash
openssl genrsa -out certs/jwt_private.pem 2048
openssl rsa -in certs/jwt_private.pem -pubout -out certs/public_key.pem
```

## 🌐 Configuration Examples

The setup scripts use intelligent defaults, but you can customize ports in `.env` after setup:

### Local Development
```env
SERVER_NAME=localhost
ISSUER=https://localhost/auth
HTTPS_PORT=8443  # Development port (no admin needed)
HTTP_PORT=8080   # Development port (no admin needed)
```
Access: https://localhost:8443

### Production
```env
SERVER_NAME=lab.university.edu
ISSUER=https://lab.university.edu/auth
HTTPS_PORT=443   # Standard HTTPS port
HTTP_PORT=80     # Standard HTTP port
```
Access: https://lab.university.edu

## 📂 Project Structure

```
├── docker-compose.yml           # Main orchestration
├── .env.example                 # Environment template
├── setup.sh / setup.bat         # Setup scripts
├── certs/                       # SSL certificates (not in git)
│   ├── fullchain.pem
│   ├── privkey.pem
│   └── public_key.pem
├── openresty/                   # NGINX + Lua proxy
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── lab_access.conf
│   └── lua/                     # Authentication scripts
├── guacamole/                   # Guacamole container
│   ├── Dockerfile
│   ├── guacamole.properties
│   └── extensions/
├── mysql/                       # Database initialization
│   ├── 001-create-schema.sql
│   ├── 002-create-admin-user.sql
│   └── 003-rdp-DOBOT.sql
└── web/                         # Homepage
    ├── index.html
    └── assets/
```

## 🔑 Default Credentials

- **Username**: `guacadmin`
- **Password**: `guacadmin`

⚠️ **Change these in production!** Access the Guacamole admin panel to create new users and disable the default account.

## 🎯 Usage

### Access Methods

1. **Direct Access**: https://yourdomain.com/guacamole/
2. **JWT Authentication**: https://yourdomain.com/guacamole/?jwt=YOUR_TOKEN
3. **Homepage**: https://yourdomain.com/

### Adding Connections

1. Login to Guacamole admin panel
2. Go to Settings → Connections
3. Add RDP/VNC/SSH connections as needed

## 🛠️ Development

### View Logs
```bash
docker-compose logs -f openresty
docker-compose logs -f guacamole
```

### Restart Services
```bash
docker-compose restart openresty
docker-compose restart guacamole
```

### Database Access
```bash
# Get the database password from .env file
docker exec -it dockerlabgateway-mysql-1 mysql -u guacamole_user -p guacamole_db
# Enter the password from MYSQL_PASSWORD in your .env file
```

## 🔒 Security Considerations

- **Setup script helps with security**: Auto-generates strong passwords
- Change default admin password after first login
- Use valid SSL certificates in production (not self-signed)
- Keep JWT private keys secure
- Regular security updates
- Network firewall configuration
- Monitor access logs

## 📚 Documentation

- [OpenResty Documentation](https://openresty.org/)
- [Apache Guacamole Manual](https://guacamole.apache.org/doc/gug/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

## 🆘 Troubleshooting

### Common Issues

**Port conflicts:**
- Change `HTTPS_PORT` and `HTTP_PORT` in `.env`
- Check what's using ports: `netstat -tulpn | grep :443`

**Certificate errors:**
- Verify certificate files exist in `certs/`
- Check certificate validity: `openssl x509 -in certs/fullchain.pem -text -noout`
- Ensure `SERVER_NAME` matches certificate CN/SAN

**Database connection issues:**
- Check MySQL container logs: `docker-compose logs mysql`
- Verify database credentials match those in `.env` file

**Guacamole not accessible:**
- Check if all containers are running: `docker-compose ps`
- Verify OpenResty configuration: `docker-compose logs openresty`

For more help, open an issue on GitHub.