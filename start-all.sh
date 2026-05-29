#!/bin/bash

set -e

BASE_DIR="$HOME/IdeaProjects"
DEPLOY_DIR="$BASE_DIR/ordexxa-deploy"
LOG_DIR="$DEPLOY_DIR/logs"

mkdir -p "$LOG_DIR"

if [ -f "$DEPLOY_DIR/.env" ]; then
  echo "Cargando variables de entorno desde $DEPLOY_DIR/.env"
  set -a
  source "$DEPLOY_DIR/.env"
  set +a
fi


echo "======================================="
echo " OrDexxa - Despliegue local empaquetado"
echo "======================================="
echo "Este despliegue NO usa IntelliJ para ejecutar la aplicación."
echo ""

export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

echo "1. Verificando PostgreSQL en puerto 5433..."
if ! pg_isready -h localhost -p 5433 >/dev/null 2>&1; then
  echo "ERROR: PostgreSQL no está respondiendo en localhost:5433."
  echo "Verifica que la base de datos local de OrDexxa esté activa."
  exit 1
fi
pg_isready -h localhost -p 5433

echo ""
echo "2. Verificando Mailpit..."
if lsof -i :8025 >/dev/null 2>&1; then
  echo "Mailpit ya está corriendo en http://localhost:8025"
else
  echo "Intentando iniciar Mailpit..."
  if command -v mailpit >/dev/null 2>&1; then
    nohup mailpit > "$LOG_DIR/mailpit.log" 2>&1 &
    sleep 3
  else
    brew services start mailpit >/dev/null 2>&1 || true
    sleep 3
  fi
fi

echo ""
echo "3. Deteniendo procesos previos en puertos 8081, 8080 y 4173..."
lsof -ti:8081 | xargs kill -9 2>/dev/null || true
lsof -ti:8080 | xargs kill -9 2>/dev/null || true
lsof -ti:4173 | xargs kill -9 2>/dev/null || true

echo ""
echo "4. Construyendo backend..."
cd "$BASE_DIR/ordexxa-backend"
./mvnw clean package -DskipTests

BACKEND_JAR=$(ls target/*.jar | grep -v original | head -n 1)

echo ""
echo "5. Construyendo API Gateway..."
cd "$BASE_DIR/ordexxa-api-gateway"
./mvnw clean package -DskipTests

GATEWAY_JAR=$(ls target/*.jar | grep -v original | head -n 1)

echo ""
echo "6. Construyendo frontend..."
cd "$BASE_DIR/ordexxa-frontend"
npm install
VITE_API_BASE_URL= npm run build

echo ""
echo "7. Levantando backend empaquetado en puerto 8081..."
cd "$BASE_DIR/ordexxa-backend"

export SERVER_PORT="${SERVER_PORT:-8081}"
export DB_URL="${DB_URL:-jdbc:postgresql://localhost:5433/ordexxa_db}"
export DB_USERNAME="${DB_USERNAME:-ordexxa_user}"
export DB_PASSWORD="${DB_PASSWORD:-ordexxa_password}"
export MAIL_HOST="${MAIL_HOST:-localhost}"
export MAIL_PORT="${MAIL_PORT:-1025}"
export MAIL_USERNAME="${MAIL_USERNAME:-}"
export MAIL_PASSWORD="${MAIL_PASSWORD:-}"
export MAIL_SMTP_AUTH="${MAIL_SMTP_AUTH:-false}"
export MAIL_SMTP_STARTTLS="${MAIL_SMTP_STARTTLS:-false}"
export MAIL_SMTP_STARTTLS_REQUIRED="${MAIL_SMTP_STARTTLS_REQUIRED:-false}"
export MAIL_SMTP_SSL_TRUST="${MAIL_SMTP_SSL_TRUST:-*}"
export MAIL_FROM="${MAIL_FROM:-no-reply@ordexxa.local}"
export AUTH_CODE_EXPIRATION_MINUTES="${AUTH_CODE_EXPIRATION_MINUTES:-15}"

nohup java -jar "$BACKEND_JAR" --server.port=8081 > "$LOG_DIR/backend.log" 2>&1 &
sleep 12

echo ""
echo "8. Levantando API Gateway empaquetado en puerto 8080..."
cd "$BASE_DIR/ordexxa-api-gateway"

export GATEWAY_PORT=8080
export BACKEND_BASE_URL=http://localhost:8081
export FRONTEND_DEV_URL=http://localhost:5173
export FRONTEND_PREVIEW_URL=http://localhost:4173
export FRONTEND_BASE_URL=http://localhost:4173

nohup java -jar "$GATEWAY_JAR" --server.port=8080 > "$LOG_DIR/gateway.log" 2>&1 &
sleep 8

echo ""
echo "9. Levantando frontend construido en puerto 4173..."
cd "$BASE_DIR/ordexxa-frontend"
nohup npm run preview -- --host 0.0.0.0 --port 4173 > "$LOG_DIR/frontend.log" 2>&1 &
sleep 4

echo ""
echo "======================================="
echo " OrDexxa desplegado correctamente"
echo "======================================="
echo "Frontend:        http://localhost:8080"
echo "Frontend directo: http://localhost:4173"
echo "API Gateway:     http://localhost:8080"
echo "Backend interno: http://localhost:8081"
echo "Mailpit:         http://localhost:8025"
echo "Swagger:         http://localhost:8081/swagger-ui/index.html"
echo "Actuator health: http://localhost:8081/actuator/health"
echo "Prometheus:      http://localhost:8081/actuator/prometheus"
echo "Logs:            $LOG_DIR"
echo ""

echo "Probando health del backend:"
curl --max-time 5 -s http://localhost:8081/actuator/health || true
echo ""
