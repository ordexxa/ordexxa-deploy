# OrDexxa - Guía general de configuración y despliegue

OrDexxa es una aplicación web desarrollada para la materia Ingeniería de Software 2.
El sistema permite gestionar funcionalidades base de una microempresa mayorista de vaporizadores, con énfasis en autenticación, verificación por correo y registro de proveedores.

## Componentes del sistema

El proyecto está dividido en estos componentes:

* `ordexxa-backend`: backend principal en Spring Boot.
* `ordexxa-api-gateway`: API Gateway con Spring Cloud Gateway.
* `ordexxa-frontend`: frontend web en React/Vite.
* `ordexxa-deploy`: scripts, variables de ejemplo y guía general de despliegue.

## Política de secretos

Por seguridad, OrDexxa no versiona secretos reales en Git.

No se deben subir:

* Archivos `.env` reales.
* API Keys.
* Contraseñas.
* Tokens.
* Credenciales productivas de base de datos.
* Credenciales de servicios externos.

Sí se deben subir:

* `.env.example`
* Código fuente.
* Scripts de ejecución.
* README de configuración.
* Archivos de configuración sin secretos.

La configuración real debe hacerse mediante variables de entorno en cada ambiente.

## Variables del backend

Estas variables se configuran en el backend, tanto en local como en Render:

```env
SERVER_PORT=8081

DB_URL=jdbc:postgresql://localhost:5433/ordexxa_db
DB_USERNAME=ordexxa_user
DB_PASSWORD=ordexxa_password

MAIL_HOST=smtp.sendgrid.net
MAIL_PORT=587
MAIL_USERNAME=apikey
MAIL_PASSWORD=TU_API_KEY_DE_SENDGRID
MAIL_SMTP_AUTH=true
MAIL_SMTP_STARTTLS=true
MAIL_SMTP_STARTTLS_REQUIRED=true
MAIL_SMTP_SSL_TRUST=smtp.sendgrid.net
MAIL_FROM=TU_CORREO_REMITENTE_VERIFICADO

AUTH_CODE_EXPIRATION_MINUTES=15
AUTH_SHOW_CODE_IN_CONSOLE=false
```

Notas:

* `MAIL_USERNAME=apikey` va literal cuando se usa SendGrid.
* `MAIL_PASSWORD` debe ser la API Key real de SendGrid, pero nunca debe subirse a Git.
* `MAIL_FROM` debe ser un remitente verificado en SendGrid.

## Variables del API Gateway

Estas variables se configuran en el API Gateway:

```env
GATEWAY_PORT=8080
BACKEND_BASE_URL=http://localhost:8081
FRONTEND_DEV_URL=http://localhost:5173
FRONTEND_PREVIEW_URL=http://localhost:4173
FRONTEND_BASE_URL=http://localhost:4173
```

En nube, `BACKEND_BASE_URL` debe apuntar al backend desplegado.

## Variables del frontend

Estas variables se configuran en el frontend:

```env
VITE_API_BASE_URL=http://localhost:8080
```

En nube, `VITE_API_BASE_URL` debe apuntar a la URL pública del API Gateway.

## SendGrid

Para enviar correos reales con SendGrid:

1. Verificar un remitente en SendGrid mediante Single Sender Verification.
2. Crear una API Key con permiso de Mail Send.
3. Configurar las variables SMTP en el backend.
4. No subir la API Key a Git.

El correo se usa para enviar el código de verificación al crear una cuenta.

## Despliegue local empaquetado

Desde este repositorio se puede ejecutar:

```bash
./start-all.sh
```

Este script compila y levanta backend, API Gateway y frontend sin usar IntelliJ.

## Configuración esperada en nube

### Render

En Render se deben configurar:

* Backend Spring Boot.
* API Gateway Spring Cloud Gateway.
* PostgreSQL.
* Variables reales de base de datos.
* Variables reales de SendGrid.

### Vercel

En Vercel se debe configurar:

* Frontend React/Vite.
* Variable `VITE_API_BASE_URL` apuntando al API Gateway.

No se debe configurar la API Key de SendGrid en Vercel.

## Checklist antes de subir a Git

Antes de hacer commit:

```bash
git status
```

Verificar que no aparezcan archivos como:

```text
.env
.env.local
.env.production
```

Solo deben versionarse archivos de ejemplo como:

```text
.env.example
```

## Flujo funcional esperado

1. Crear cuenta.
2. Recibir correo real con código de verificación.
3. Verificar código.
4. Iniciar sesión.
5. Registrar proveedor con usuario autenticado.
6. Consultar evidencias en Swagger, Actuator, Prometheus, base de datos y logs.

## Redis / caché distribuida

Redis se usa como tecnología externa de caché distribuida para el backend de OrDexxa. No hace parte del frontend ni del API Gateway, y tampoco se empaqueta dentro del JAR del backend.

En local, Redis debe estar instalado y encendido antes de ejecutar el despliegue empaquetado:

```bash
brew services start redis
redis-cli ping
```

El resultado esperado es:

```text
PONG
```

En local el backend se conecta a:

```env
REDIS_URL=redis://localhost:6379
```

En nube se debe crear un Redis administrado, por ejemplo en Upstash Redis, Redis Cloud o un servicio equivalente. El proveedor entregará una URL segura que normalmente tiene este formato:

```env
REDIS_URL=<URL_REDIS_SEGURA_DEL_PROVEEDOR>
```

Esa URL se configura como variable de entorno del backend desplegado. No se debe subir a Git porque puede contener usuario, contraseña o token.

El backend ya está preparado para usar Redis mediante Spring Data Redis y Spring Cache. Actualmente se cachean endpoints de lectura frecuente como catálogos, parámetros del sistema y plantillas de notificación, usando llaves con prefijo:

```text
ordexxa::
```

El tiempo de vida de la caché se controla con:

```env
CACHE_TTL=30m
```

Variables requeridas para Redis en backend:

```env
CACHE_TYPE=redis
REDIS_URL=redis://localhost:6379
REDIS_TIMEOUT=2s
CACHE_TTL=30m
CACHE_KEY_PREFIX=ordexxa::
ACTUATOR_REDIS_HEALTH_ENABLED=true
REDIS_REPOSITORIES_ENABLED=false
```

Para verificar Redis en ejecución:

```bash
curl -s http://localhost:8081/actuator/health
redis-cli --scan --pattern 'ordexxa::*'
redis-cli --scan --pattern 'ordexxa::*' | while read key; do echo "$key -> TTL $(redis-cli ttl "$key") segundos"; done
```

En despliegue cloud no se cambia código: solo se configura `REDIS_URL` con la URL segura del Redis administrado.
