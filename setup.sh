#!/bin/bash

# =================================================================
# DecentraLabs Gateway - Quick Setup Script
# =================================================================

echo "🚀 DecentraLabs Gateway - Quick Setup"
echo "======================================"
echo

# Check prerequisites
echo "🔍 Checking prerequisites..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "   Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed."
    echo "   Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker and Docker Compose are available"
echo

# Check if .env already exists
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists!"
    read -p "Do you want to overwrite it? (y/N): " overwrite
    if [[ ! $overwrite =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

# Copy template
cp .env.example .env
echo "✅ Created .env file from template"
echo

# Ask for domain
echo "🌐 Domain Configuration"
echo "----------------------"
echo "Enter your domain name (or press Enter for localhost):"
read -p "Domain [localhost]: " domain
domain=${domain:-localhost}

# Update .env with intelligent defaults
if [[ "$domain" == "localhost" ]]; then
    echo "🔧 Configuring for local development..."
    sed -i 's/SERVER_NAME=.*/SERVER_NAME=localhost/' .env
    sed -i 's/ISSUER=.*/ISSUER=https:\/\/localhost\/auth/' .env
    sed -i 's/HTTPS_PORT=.*/HTTPS_PORT=8443/' .env
    sed -i 's/HTTP_PORT=.*/HTTP_PORT=8080/' .env
    echo "   - Server: https://localhost:8443"
    echo "   - Using development ports (8443/8080) - no admin needed"
else
    echo "🔧 Configuring for production..."
    sed -i "s/SERVER_NAME=.*/SERVER_NAME=$domain/" .env
    sed -i "s/ISSUER=.*/ISSUER=https:\/\/$domain\/auth/" .env
    sed -i 's/HTTPS_PORT=.*/HTTPS_PORT=443/' .env
    sed -i 's/HTTP_PORT=.*/HTTP_PORT=80/' .env
    echo "   - Server: https://$domain"
    echo "   - Using standard ports (443/80)"
fi

echo "💡 To use different ports, edit HTTPS_PORT/HTTP_PORT in .env after setup"

echo
echo "🔐 SSL Certificates"
echo "-------------------"

# Check if certificates exist
if [ ! -d "certs" ]; then
    mkdir -p certs
fi

if [ ! -f "certs/fullchain.pem" ] || [ ! -f "certs/privkey.pem" ]; then
    echo "❌ SSL certificates not found!"
    echo
    echo "You need to add SSL certificates to the 'certs' folder:"
    echo "  - certs/fullchain.pem (certificate)"
    echo "  - certs/privkey.pem (private key)"
    echo "  - certs/public_key.pem (JWT public key)"
    echo
    
    if [[ "$domain" == "localhost" ]]; then
        read -p "Generate self-signed certificates for localhost? (Y/n): " generate
        if [[ ! $generate =~ ^[Nn]$ ]]; then
            echo "🔧 Generating self-signed certificates..."
            
            # Generate self-signed certificate for localhost
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout certs/privkey.pem \
                -out certs/fullchain.pem \
                -subj "/C=ES/ST=Local/L=Dev/O=Dev/CN=localhost"
            
            # Generate JWT keys
            openssl genrsa -out certs/jwt_private.pem 2048
            openssl rsa -in certs/jwt_private.pem -pubout -out certs/public_key.pem
            
            echo "✅ Self-signed certificates generated!"
        fi
    else
        echo "For production, you need valid SSL certificates from:"
        echo "  - Let's Encrypt (certbot)"
        echo "  - Your certificate authority"
        echo "  - Cloud provider (AWS ACM, etc.)"
    fi
else
    echo "✅ SSL certificates found"
fi

echo
echo "🎯 Next Steps"
echo "-------------"
echo "1. Review and customize .env file if needed"
echo "2. Ensure SSL certificates are in place"

# Ask if user wants to start services
echo
read -p "🚀 Start the services now? (Y/n): " start_services
if [[ ! $start_services =~ ^[Nn]$ ]]; then
    echo "Starting DecentraLabs Gateway services..."
    if command -v docker-compose &> /dev/null; then
        docker-compose up -d
    else
        docker compose up -d
    fi
    
    echo
    echo "✅ Services started successfully!"
    echo "🌐 Access your gateway at:"
    echo "   https://$domain$([ "$domain" == "localhost" ] && echo ":8443" || echo "")"
    echo
    echo "📊 To view logs: docker-compose logs -f"
    echo "🔧 To stop: docker-compose down"
else
    echo "3. Run: docker-compose up -d"
    echo "4. Access: https://$domain$([ "$domain" == "localhost" ] && echo ":8443" || echo "")"
fi

echo
echo "📚 For more information, see README.md"
echo "🚀 Setup complete!"