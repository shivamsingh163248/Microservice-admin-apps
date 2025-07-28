# 🚀 How to Pull and Run Microservices Locally

This guide explains how to pull and run the microservices images from GitHub Container Registry (GHCR) and Docker Hub on your local machine.

## 📦 Available Images

### GitHub Container Registry (GHCR)
```
ghcr.io/shivamsingh163248/flask_backend:v1.0.X
ghcr.io/shivamsingh163248/nginx_frontend:v1.0.X
ghcr.io/shivamsingh163248/mysql_db:v1.0.X
```

### Docker Hub
```
shivamsingh163248/flask_backend:v1.0.X
shivamsingh163248/nginx_frontend:v1.0.X
shivamsingh163248/mysql_db:v1.0.X
```

## 🐳 Method 1: Pull Images from GitHub Container Registry (GHCR)

### Step 1: Login to GitHub Container Registry (if images are private)

```bash
# Login using GitHub Personal Access Token
echo YOUR_GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# Or using interactive login
docker login ghcr.io
```

### Step 2: Pull Individual Images

```bash
# Pull backend image
docker pull ghcr.io/shivamsingh163248/flask_backend:v1.0.1

# Pull frontend image
docker pull ghcr.io/shivamsingh163248/nginx_frontend:v1.0.1

# Pull database image
docker pull ghcr.io/shivamsingh163248/mysql_db:v1.0.1

# Or pull latest versions
docker pull ghcr.io/shivamsingh163248/flask_backend:latest
docker pull ghcr.io/shivamsingh163248/nginx_frontend:latest
docker pull ghcr.io/shivamsingh163248/mysql_db:latest
```

### Step 3: Verify Images are Downloaded

```bash
# List all downloaded images
docker images | grep ghcr.io/shivamsingh163248

# Check specific images
docker images ghcr.io/shivamsingh163248/flask_backend
docker images ghcr.io/shivamsingh163248/nginx_frontend
docker images ghcr.io/shivamsingh163248/mysql_db
```

## 🐳 Method 2: Pull Images from Docker Hub

### Step 1: Login to Docker Hub (if images are private)

```bash
# Login to Docker Hub
docker login

# Or specify credentials
echo YOUR_DOCKER_PASSWORD | docker login -u YOUR_DOCKER_USERNAME --password-stdin
```

### Step 2: Pull Individual Images

```bash
# Pull backend image
docker pull shivamsingh163248/flask_backend:v1.0.1

# Pull frontend image
docker pull shivamsingh163248/nginx_frontend:v1.0.1

# Pull database image
docker pull shivamsingh163248/mysql_db:v1.0.1

# Or pull latest versions
docker pull shivamsingh163248/flask_backend:latest
docker pull shivamsingh163248/nginx_frontend:latest
docker pull shivamsingh163248/mysql_db:latest
```

## 🧱 Method 3: Run Using Docker Compose (GitHub Container Registry)

### Step 1: Create docker-compose.github.yml

Create a file named `docker-compose.github.yml`:

```yaml
version: '3.8'

services:
  database:
    image: ghcr.io/shivamsingh163248/mysql_db:latest
    container_name: mysql_db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: adminapp
      MYSQL_USER: adminuser
      MYSQL_PASSWORD: adminpass
    volumes:
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
      - mysql_data:/var/lib/mysql
    ports:
      - "3306:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
    networks:
      - microservice-network

  backend:
    image: ghcr.io/shivamsingh163248/flask_backend:latest
    container_name: flask_backend
    restart: always
    environment:
      DB_HOST: database
      DB_USER: adminuser
      DB_PASS: adminpass
      DB_NAME: adminapp
    ports:
      - "5000:5000"
    depends_on:
      database:
        condition: service_healthy
    networks:
      - microservice-network

  frontend:
    image: ghcr.io/shivamsingh163248/nginx_frontend:latest
    container_name: nginx_frontend
    restart: always
    ports:
      - "8080:80"
    depends_on:
      - backend
    networks:
      - microservice-network

volumes:
  mysql_data:
    driver: local

networks:
  microservice-network:
    driver: bridge
```

### Step 2: Run with Docker Compose

```bash
# Pull and run all services from GHCR
docker-compose -f docker-compose.github.yml up -d

# View logs
docker-compose -f docker-compose.github.yml logs

# Stop services
docker-compose -f docker-compose.github.yml down
```

## 🧱 Method 4: Run Using Docker Compose (Docker Hub)

### Step 1: Create docker-compose.dockerhub.yml

Create a file named `docker-compose.dockerhub.yml`:

```yaml
version: '3.8'

services:
  database:
    image: shivamsingh163248/mysql_db:latest
    container_name: mysql_db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: adminapp
      MYSQL_USER: adminuser
      MYSQL_PASSWORD: adminpass
    volumes:
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
      - mysql_data:/var/lib/mysql
    ports:
      - "3306:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
    networks:
      - microservice-network

  backend:
    image: shivamsingh163248/flask_backend:latest
    container_name: flask_backend
    restart: always
    environment:
      DB_HOST: database
      DB_USER: adminuser
      DB_PASS: adminpass
      DB_NAME: adminapp
    ports:
      - "5000:5000"
    depends_on:
      database:
        condition: service_healthy
    networks:
      - microservice-network

  frontend:
    image: shivamsingh163248/nginx_frontend:latest
    container_name: nginx_frontend
    restart: always
    ports:
      - "8080:80"
    depends_on:
      - backend
    networks:
      - microservice-network

volumes:
  mysql_data:
    driver: local

networks:
  microservice-network:
    driver: bridge
```

### Step 2: Run with Docker Compose

```bash
# Pull and run all services from Docker Hub
docker-compose -f docker-compose.dockerhub.yml up -d

# View logs
docker-compose -f docker-compose.dockerhub.yml logs

# Stop services
docker-compose -f docker-compose.dockerhub.yml down
```

## 🏃‍♂️ Method 5: Run Individual Containers Manually

### Running from GitHub Container Registry

```bash
# 1. Create a network
docker network create microservice-network

# 2. Run MySQL database
docker run -d \
  --name mysql_db \
  --network microservice-network \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=adminapp \
  -e MYSQL_USER=adminuser \
  -e MYSQL_PASSWORD=adminpass \
  -p 3306:3306 \
  ghcr.io/shivamsingh163248/mysql_db:latest

# 3. Wait for database to start (about 30 seconds), then run backend
docker run -d \
  --name flask_backend \
  --network microservice-network \
  -e DB_HOST=mysql_db \
  -e DB_USER=adminuser \
  -e DB_PASS=adminpass \
  -e DB_NAME=adminapp \
  -p 5000:5000 \
  ghcr.io/shivamsingh163248/flask_backend:latest

# 4. Run frontend
docker run -d \
  --name nginx_frontend \
  --network microservice-network \
  -p 8080:80 \
  ghcr.io/shivamsingh163248/nginx_frontend:latest
```

### Running from Docker Hub

```bash
# 1. Create a network
docker network create microservice-network

# 2. Run MySQL database
docker run -d \
  --name mysql_db \
  --network microservice-network \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=adminapp \
  -e MYSQL_USER=adminuser \
  -e MYSQL_PASSWORD=adminpass \
  -p 3306:3306 \
  shivamsingh163248/mysql_db:latest

# 3. Wait for database to start (about 30 seconds), then run backend
docker run -d \
  --name flask_backend \
  --network microservice-network \
  -e DB_HOST=mysql_db \
  -e DB_USER=adminuser \
  -e DB_PASS=adminpass \
  -e DB_NAME=adminapp \
  -p 5000:5000 \
  shivamsingh163248/flask_backend:latest

# 4. Run frontend
docker run -d \
  --name nginx_frontend \
  --network microservice-network \
  -p 8080:80 \
  shivamsingh163248/nginx_frontend:latest
```

## 📋 Prerequisites

### Required Software

```bash
# Install Docker Desktop (Windows/Mac) or Docker Engine (Linux)
# Download from: https://www.docker.com/products/docker-desktop/

# Verify Docker installation
docker --version
docker-compose --version

# Check Docker is running
docker ps
```

### Required Files (Optional)

If you have the database initialization script:

```bash
# Create database directory and add init.sql
mkdir database
# Place your init.sql file in the database/ directory
```

## 🌐 Access Your Application

After running the containers, access your application:

- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:5000
- **Database**: localhost:3306
- **Backend Health Check**: http://localhost:5000/health

## 🔍 Troubleshooting

### Check Container Status

```bash
# List running containers
docker ps

# Check container logs
docker logs flask_backend
docker logs nginx_frontend
docker logs mysql_db

# Check container health
docker inspect mysql_db --format='{{.State.Health.Status}}'
```

### Common Issues

1. **Port Already in Use**
   ```bash
   # Kill processes using the ports
   # Windows
   netstat -ano | findstr :8080
   taskkill /PID <PID> /F
   
   # Linux/Mac
   lsof -ti:8080 | xargs kill -9
   ```

2. **Database Connection Failed**
   ```bash
   # Wait for database to fully start
   docker logs mysql_db
   
   # Check if database is ready
   docker exec mysql_db mysqladmin ping -h localhost -u root -prootpass
   ```

3. **Images Not Found**
   ```bash
   # Check if you're logged in
   docker login ghcr.io
   docker login
   
   # Check image names and tags
   docker search shivamsingh163248
   ```

## 🧹 Cleanup

### Stop and Remove Containers

```bash
# Using docker-compose
docker-compose -f docker-compose.github.yml down
docker-compose -f docker-compose.dockerhub.yml down

# Remove containers manually
docker stop flask_backend nginx_frontend mysql_db
docker rm flask_backend nginx_frontend mysql_db

# Remove network
docker network rm microservice-network

# Remove volumes (data will be lost)
docker volume rm microservice-admin-app_mysql_data
```

### Remove Images

```bash
# Remove specific images
docker rmi ghcr.io/shivamsingh163248/flask_backend:latest
docker rmi ghcr.io/shivamsingh163248/nginx_frontend:latest
docker rmi ghcr.io/shivamsingh163248/mysql_db:latest

# Remove all unused images
docker image prune -a
```

## 🎯 Quick Start Commands

### GitHub Container Registry (One Command)

```bash
# Clone repo and run from GHCR
git clone https://github.com/shivamsingh163248/Microservice-admin-apps.git
cd Microservice-admin-apps
docker-compose -f docker-compose.github.yml up -d
```

### Docker Hub (One Command)

```bash
# Clone repo and run from Docker Hub
git clone https://github.com/shivamsingh163248/Microservice-admin-apps.git
cd Microservice-admin-apps
docker-compose -f docker-compose.dockerhub.yml up -d
```

## 🚀 Production Tips

1. **Use specific version tags** instead of `latest` for production
2. **Set up health checks** for all services
3. **Use environment files** for sensitive configuration
4. **Monitor container logs** regularly
5. **Set up proper backup** for database volumes

---

**🎉 You're all set!** Your microservices should now be running locally. Visit http://localhost:8080 to see your application!
