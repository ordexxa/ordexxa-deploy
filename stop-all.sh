#!/bin/bash

echo "Deteniendo despliegue local de OrDexxa..."

lsof -ti:8081 | xargs kill -9 2>/dev/null || true
lsof -ti:8080 | xargs kill -9 2>/dev/null || true
lsof -ti:4173 | xargs kill -9 2>/dev/null || true

echo "Servicios detenidos."
